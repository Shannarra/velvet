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

        tokens << token unless [SyntaxKind::WhitespaceToken].include? token.kind
      end

      # append last token IF it's good
      next_tok = lexer.lex!
      tokens << token unless [SyntaxKind::WhitespaceToken].include? next_tok.kind

      @tokens = Array(tokens)
      @diagnostics << lexer.diagnostics
      @diagnostics.flatten!
    end

    def parse!
      expr = parse_expression

      eof = match(SyntaxKind::IdentifierToken)

      @scope.root.children << SyntaxTree.new(@diagnostics, expr, eof)

      binding.pry unless eof.kind == SyntaxKind::NewlineToken

      @tokens.shift(@ip)
      @ip = 0

      parse!
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
      # if line is empty just match both eof & newline
#      return next_token if current.kind == SyntaxKind::EOFToken && kind == SyntaxKind::NewlineToken

      return current if current.kind == SyntaxKind::EOFToken

      # match expected token if available
      # skip over newline token
      return next_token if [kind, SyntaxKind::NewlineToken].include? current.kind

      if [SyntaxKind::TabToken, SyntaxKind::WhitespaceToken, SyntaxKind::CommentToken].include? current.kind
        next_token
        return next_token
      end

      puts "[DIAGNOSTICS]:\n\n#{diagnostics}\n\n" unless diagnostics.empty?

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
      if current.kind == SyntaxKind::OpenParenthesisToken
        left = next_token
        expr = parse_expression
        right = match(SyntaxKind::CloseParenthesisToken)
        return ParenthesizedExpressionSyntax.new(left, expr, right)
      end

      if current.kind == SyntaxKind::NumberToken
        num = match(SyntaxKind::NumberToken)
        return NumberExpressionSyntax.new(num)
      end

      return if current.kind == SyntaxKind::NewlineToken

      parse_id
    end

    def parse_id
      id = next_token

      next_token while Constants::Kinds::SPACES.include?(current.kind)

      if current.kind == SyntaxKind::AssignmentToken
        _assignment_op = match(SyntaxKind::AssignmentToken)
        right = parse_expression

        return AssignmentExpressionSyntax.new(id, right)
      end

      IdentifierExpressionSyntax.new(id)
    end
  end
end
