# frozen_string_literal: true

require_relative 'lexer'
require_relative 'base'

module Syntax
  module ParsingHelpers
    def binary_operator_precedence(kind)
      case kind
      when SyntaxKind::StarToken, SyntaxKind::SlashToken, SyntaxKind::DoubleStarToken, SyntaxKind::ModuloToken then 2
      when SyntaxKind::PlusToken, SyntaxKind::MinusToken,
           *Constants::Kinds::BOOLEAN_OPERATORS
        1
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
        left = SyntaxNode.new(SyntaxNodeType::BinaryExpression, left:, operator:, right:)
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
        left = SyntaxNode.new(SyntaxNodeType::BinaryExpression, left:, operator:, right:)
      end

      left
    end

    def parse_primary_expr
      case current.kind
      when SyntaxKind::OpenParenthesisToken then parse_parenthesized
      when SyntaxKind::OpenBracketToken then parse_array
      when SyntaxKind::NumberToken
        token = next_token
        is_integer = token.value.is_a? Integer

        SyntaxNode.new(SyntaxNodeType::NumberExpression, token:, is_integer:)
      when SyntaxKind::IdentifierToken then parse_id
      when SyntaxKind::StringToken then SyntaxNode.new(SyntaxNodeType::StringExpression, token: next_token)
      when SyntaxKind::BuiltinFunction
        name = next_token
        args = parse_expression
        SyntaxNode.new(SyntaxNodeType::BuiltinFunctionExpression, name:, args:)
      when *Constants::Kinds::KEYWORDS then parse_keyword
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

        return SyntaxNode.new(SyntaxNodeType::AssignmentExpression, id:, value: right)

      elsif current.kind == SyntaxKind::OpenBracketToken
        index_open_bracket = match(SyntaxKind::OpenBracketToken)
        index = parse_expression
        index_close_bracket = match(SyntaxKind::CloseBracketToken)

        aie = SyntaxNode.new(SyntaxNodeType::ArrayIndexingExpression,
                             array_id: id,
                             open_token: index_open_bracket,
                             index:,
                             closed_token: index_close_bracket)

        if current.kind == SyntaxKind::AssignmentToken
          next_token

          right = parse_expression

          return SyntaxNode.new(SyntaxNodeType::ArrayIndexingAssignmentExpression, array_indexing_expression: aie, right:)
        end

        return aie
      end

      SyntaxNode.new(SyntaxNodeType::IdentifierExpression, id:)
    end

    def parse_parenthesized
      left = next_token
      expression = parse_expression
      right = match(SyntaxKind::CloseParenthesisToken)

      SyntaxNode.new(SyntaxNodeType::ParenthesizedExpression, open_token: left, expression:, closed_token: right)
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

      SyntaxNode.new(SyntaxNodeType::ArrayExpression, open_token: left, items: body, closed_token: right)
    end

    def parse_keyword
      if current.kind == SyntaxKind::KWRD_IF
        keyword = next_token

        condition = parse_expression
        cond = SyntaxNode.new(SyntaxNodeType::IfExpression, keyword:, condition:, condition_branches: [])

        match(SyntaxKind::KWRD_DO)

        body_end_kinds = [SyntaxKind::KWRD_ELSE, SyntaxKind::KWRD_END, SyntaxKind::EOFToken]
        body = parse_body(keyword: SyntaxKind::KWRD_DO, body_end_kinds:)
        cond.condition_branches << body

        if current.kind != SyntaxKind::KWRD_END
          next_token
          cond.condition_branches << parse_body(keyword: SyntaxKind::KWRD_ELSE, body_end_kinds:)
        end

        next_token

        cond
      elsif [SyntaxKind::KWRD_TRUE, SyntaxKind::KWRD_FALSE].include?(current.kind)
        SyntaxNode.new(SyntaxNodeType::BooleanExpression, token: current)
        next_token
      elsif current.kind == SyntaxKind::KWRD_FROM
        parse_from_to_loop
      elsif current.kind == SyntaxKind::KWRD_BREAK
        token = current
        next_token
        SyntaxNode.new(
          SyntaxNodeType::BreakExpression,
          token:
        )
      else
        raise "Unexpected keyword \"#{current.text}\" found at #{current.start_printing_position}"
      end
    end

    def parse_body(keyword:, body_end_kinds: [SyntaxKind::KWRD_END, SyntaxKind::EOFToken])
      body_items = []

      until body_end_kinds.include?(current.kind)
        expr = parse_expression

        body_items << expr
      end

      body_end = current

      SyntaxNode.new(SyntaxNodeType::BodyExpression, keyword:, body_items:, body_end:)
    end

    def parse_from_to_loop
      keyword = next_token

      lower_assignment = parse_expression

      unless lower_assignment.kind == SyntaxNodeType::AssignmentExpression
        raise "Expected variable assignment as first argument of from loop, got #{lower_assignment.kind} instead."
      end

      raise "For loop expected upper bound, #{to_candidate.text} found." unless current.kind == SyntaxKind::KWRD_TO

      # Consume the "to" token
      next_token

      upper_bound = parse_expression

      loop_step = nil
      if current.kind == SyntaxKind::KWRD_STEP
        next_token

        loop_step = parse_expression
      end

      _do_token = match(SyntaxKind::KWRD_DO)
      loop_body = parse_body(keyword:)

      next_token
      SyntaxNode.new(
        SyntaxNodeType::ForLoopExpression,
        keyword:,
        lower_assignment:,
        upper_bound:,
        loop_step:,
        loop_body:
      )
    end
  end
end
