# frozen_string_literal: true

module Syntax
  class SyntaxNode
    # Moving to tagged union - style implementation to simplify usage
    # and move away from using Ruby reflections (i.e. "x.is_a?(Y)") in the
    # evaluation processing

    attr_reader :kind,
                :left, :operator, :right,
                :token, :is_integer,
                :open_token, :expression, :closed_token,
                :items,
                :array_id, :index,
                :array_indexing_expression,
                :id,
                :value,
                :name, :args

    # rubocop:disable Metrics/ParameterLists
    def initialize(kind, children: nil,
                   left: nil, operator: nil, right: nil, # binary expressions
                   token: nil, is_integer: nil, # binary expressions
                   open_token: nil, expression: nil, closed_token: nil, # binary expressions
                   items: nil, # binary expressions
                   array_id: nil, index: nil, # binary expressions
                   array_indexing_expression: nil, # binary expressions
                   id: nil, # binary expressions
                   value: nil, # binary expressions
                   name: nil, args: nil) # binary expressions
      # rubocop:enable Metrics/ParameterLists
      @kind = kind
      @children = Array(children)

      @left = left
      @operator = operator
      @right = right
      @token = token
      @is_integer = is_integer
      @open_token = open_token
      @expression = expression
      @closed_token = closed_token
      @items = items
      @array_id = array_id
      @index = index
      @array_indexing_expression = array_indexing_expression
      @id = id
      @value = value
      @name = name
      @args = args
    end

    def children(&block)
      return @children.each(&block) if block_given?

      @children
    end
  end

  class GlobalScope < SyntaxNode
    def initialize
      super(
        :GLOBAL_SCOPE,
        children: [],
      )
    end
  end

  SyntaxNodeType = enum %w[
    NumberExpression
    StringExpression

    IdentifierExpression
    AssignmentExpression

    BinaryExpression
    ParenthesizedExpression

    ArrayExpression
    ArrayIndexingExpression
    ArrayIndexingAssignmentExpression

    BuiltinFunctionExpression
  ].freeze

  class ExpressionSyntax < SyntaxNode
    def initialize(kind, children: nil)
      super
      @children = children
    end

    def debug_print!
      pretty_print_tree self
      nil
    end
  end
end
