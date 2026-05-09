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
                :name, :args,
                :keyword,
                :condition,
                :condition_branches,
                :body_items, :body_end,
                :lower_assignment, :upper_bound, :loop_body, :loop_step

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
                   name: nil, args: nil, # built-in expressions
                   keyword: nil, # generic keyword expression
                   condition: nil, condition_branches: nil, # conditional expression
                   body_items: nil, body_end: nil, # body expression
                   lower_assignment: nil, upper_bound: nil, loop_step: nil, loop_body: nil) # for loop expression
      # rubocop:enable Metrics/ParameterLists
      @kind = kind
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
      @keyword = keyword
      @condition = condition
      @condition_branches = condition_branches
      @body_items = body_items
      @body_end = body_end
      @lower_assignment = lower_assignment
      @upper_bound = upper_bound
      @loop_step = loop_step
      @loop_body = loop_body

      @children = if children.nil?
                    children_for_kind
                  else
                    Array(children)
                  end
    end

    def children(&block)
      return @children.each(&block) if block_given?

      @children
    end

    def children_for_kind
      case kind
      when :scope then @children
      when SyntaxNodeType::NumberExpression,
           SyntaxNodeType::StringExpression,
           SyntaxNodeType::BooleanExpression then [token]
      when SyntaxNodeType::IdentifierExpression then [id]
      when SyntaxNodeType::AssignmentExpression then [id, value]
      when SyntaxNodeType::BinaryExpression then [left, operator, right]
      when SyntaxNodeType::ParenthesizedExpression then [open_token, expression, closed_token]
      when SyntaxNodeType::ArrayExpression then [open_token, items, closed_token]
      when SyntaxNodeType::ArrayIndexingExpression then [array_id, open_token, index, closed_token]
      when SyntaxNodeType::ArrayIndexingAssignmentExpression then [array_indexing_expression, value]
      when SyntaxNodeType::BuiltinFunctionExpression then [name, args]
      when SyntaxNodeType::IfExpression then [keyword, condition, condition_branches]
      when SyntaxNodeType::BodyExpression, SyntaxNodeType::ConditionalExpression then [keyword, body_items, body_end]
      when SyntaxNodeType::ForLoopExpression then [lower_assignment, upper_bound, loop_body, loop_step]
      else
        raise "Unknown children for kind #{kind}. Fix #{__FILE__}:#{__LINE__}"
      end
    end

    def debug_print!
      pretty_print_tree self
      nil
    end
  end

  class Scope < SyntaxNode
    attr_accessor :variables, :parent, :name

    def initialize(variables, parent, name, **rest)
      @variables = variables
      @parent = parent
      @name = name

      super(
        :scope,
        **rest
      )
    end
  end

  class GlobalScope < Scope
    def initialize(variables = {})
      super(
        variables,
        nil,
        :GLOBAL_SCOPE,
        children: [],
      )
    end
  end

  SyntaxNodeType = enum %w[
    BaseExpression

    NumberExpression
    StringExpression
    BooleanExpression

    IdentifierExpression
    AssignmentExpression

    BinaryExpression
    ParenthesizedExpression

    ArrayExpression
    ArrayIndexingExpression
    ArrayIndexingAssignmentExpression

    BuiltinFunctionExpression

    ConditionalExpression
    IfExpression
    ElseExpression
    BodyExpression

    ForLoopExpression
  ].freeze
end
