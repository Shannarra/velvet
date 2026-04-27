# frozen_string_literal: true

require_relative 'lexer'
require_relative 'base'

module Syntax
  module ParsingHelpers
    def binary_operator_precedence(kind)
      case kind
      when SyntaxKind::StarToken, SyntaxKind::SlashToken, SyntaxKind::DoubleStarToken then 2
      when SyntaxKind::PlusToken, SyntaxKind::MinusToken then 1
      else 0
      end
    end
  end

  class Parser # rubocop:disable Metrics/ClassLength
    include ParsingHelpers

    attr_reader :diagnostics

    def initialize(text, scope)
      @text = text
      @tokens = []
      @diagnostics = []
      @ip = 0

      @scope = scope

      tokens = []
      lexer = Lexer.new(text)
      token = nil

      until !token.nil? && token.kind == SyntaxKind::EOFToken
        token = lexer.lex!
        break if token.nil?

        tokens << token unless Constants::Kinds::VOID.include? token.kind
      end

      # append last token IF it's good
      next_tok = lexer.lex!
      tokens << token unless Constants::Kinds::VOID.include? next_tok.kind

      @tokens = Array(tokens)
      @diagnostics << lexer.diagnostics
      @diagnostics.flatten!
    end

    def parse!
      expr = parse_expression
      store_expression(expr)

      # recursive decent until EOF reached
      return parse! unless current.kind == SyntaxKind::EOFToken

      match(SyntaxKind::EOFToken)
    end

    def parse_expression(parent_precedence = 0)
      left = parse_factor

      loop do
        precedence = binary_operator_precedence(current.kind)
        break if precedence.zero? || precedence <= parent_precedence

        operator = next_token
        right = parse_expression(precedence)
        left = BinaryExpressionSyntax.new(left, operator, right)
      end

      left
    end

    private

    def store_expression(root, eof_token = current, scope = @scope)
      @scope.root.children << SyntaxTree.new(@diagnostics, root, eof_token, scope)
    end

    def peek(offset = 1)
      id = @ip + offset
      return @tokens[-1] if id >= @tokens.count

      @tokens[id]
    end

    def current
      peek(0)
    end

    def next_token
      curr = current
      @ip += 1
      curr
    end

    def match(kind)
      return next_token if current.kind == kind

      diagnostics << "Unexpected token <#{current.kind}>. Expected <#{kind}> at #{current.position}"
      Token.new(SyntaxKind::BadToken, current.position, nil, nil)
    end

    def parse_factor
      left = parse_primary_expr

      while [SyntaxKind::StarToken, SyntaxKind::SlashToken].include? current.kind
        operator = if current.kind == SyntaxKind::StarToken && peek(1)&.kind == SyntaxKind::StarToken
                     next_token
                     next_token
                     operator = Token.new(SyntaxKind::DoubleStarToken, current.position, '**', nil)
                   else
                     next_token
                   end

        right = parse_primary_expr
        left = BinaryExpressionSyntax.new(left, operator, right)
      end

      left
    end

    def parse_primary_expr
      case current.kind
      when SyntaxKind::OpenParenthesisToken then parse_parenthesized
      when SyntaxKind::OpenBracketToken then parse_array
      when SyntaxKind::NumberToken then NumberExpressionSyntax.new(next_token)
      when SyntaxKind::IdentifierToken then parse_id
      when SyntaxKind::StringToken then StringExpressionSyntax.new(next_token)
      when SyntaxKind::BuiltinFunction
        name = next_token
        args = parse_expression
        BuiltinFunctionSyntax.new(name, args)
      else
        prev = peek(-1)

        err_msg = "Unexpected token \"#{prev.value}\" (#{prev.kind}) found at #{prev.start_printing_position}"
        err_msg += ', expected EOF' if current.kind == SyntaxKind::EOFToken

        raise err_msg
      end
    end

    def parse_id
      id = next_token

      if current.kind == SyntaxKind::AssignmentToken
        _assignment_op = match(SyntaxKind::AssignmentToken)
        right = parse_expression

        return AssignmentExpressionSyntax.new(id, right)

      elsif current.kind == SyntaxKind::OpenBracketToken
        index_open_bracket = match(SyntaxKind::OpenBracketToken)
        index = next_token
        index_close_bracket = match(SyntaxKind::CloseBracketToken)

        aie = ArrayIndexingExpressionSyntax.new(id, index_open_bracket, index, index_close_bracket)

        if current.kind == SyntaxKind::AssignmentToken
          next_token

          right = parse_expression

          return ArrayIndexingAssignmentExpressionSyntax.new(aie, right)
        end

        return aie
      end

      IdentifierExpressionSyntax.new(id)
    end

    def parse_parenthesized
      left = next_token
      expr = parse_expression
      right = match(SyntaxKind::CloseParenthesisToken)
      ParenthesizedExpressionSyntax.new(left, expr, right)
    end

    def parse_array
      left = next_token
      body = []

      until current.kind == SyntaxKind::CloseBracketToken
        expr = parse_expression

        match(SyntaxKind::CommaToken) unless current.kind == SyntaxKind::CloseBracketToken

        body << expr
      end

      right = match(SyntaxKind::CloseBracketToken)

      ArrayExpressionSyntax.new(left, body, right)
    end
  end
end
