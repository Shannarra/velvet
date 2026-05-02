# frozen_string_literal: true

module Syntax
  class Evaluator # rubocop:disable Metrics/ClassLength
    attr_reader :diagnostics

    def initialize(root, parent_scope)
      @root = root
      @diagnostics = []
      @parent_scope = parent_scope
      @variables = parent_scope.variables
    end

    def eval!
      evaluate_expr! @root
    end

    def self.eval_tree!(tree)
      diagnostics = []
      tree.root.children.each do |sub|
        ev = new(sub.root, tree.scope)

        ev.eval!

        diagnostics << ev.diagnostics
      end

      diagnostics
    end

    EVALUATION_METHODS = {
      NumberExpression: :self_token,
      StringExpression: :self_token,
      BooleanExpression: :self_token,
      IdentifierExpression: :evaluate_identifier,
      AssignmentExpression: :evaluate_assignment,
      ParenthesizedExpression: :evaluate_sub_expr,
      BinaryExpression: :evaluate_binary,
      ArrayExpression: :evaluate_array,
      ArrayIndexingExpression: :evaluate_array_indexing,
      ArrayIndexingAssignmentExpression: :evaluate_array_indexing_assignment,
      GlobalScope: :evaluate_global_scope,
      BuiltinFunctionExpression: :evaluate_builtin_function,
      IfExpression: :evaluate_condition,
      BodyExpression: :evaluate_body,
      KWRD_TRUE: :wrap_to_node,
      KWRD_FALSE: :wrap_to_node
    }.freeze

    private

    def evaluate_expr!(expr)
      unless EVALUATION_METHODS.key?(expr.kind.to_sym)
        raise "[EVALUATION]: Unexpected node \"#{expr.kind}\" - I don't know how to handle it."
      end

      __send__(EVALUATION_METHODS[expr.kind.to_sym], expr)
    end

    def self_token(expr)
      expr.token
    end

    def wrap_to_node(expr)
      type = case expr.kind
             when SyntaxKind::KWRD_TRUE, SyntaxKind::KWRD_FALSE
               SyntaxNodeType::BooleanExpression
             else
               raise "Could not wrap expression #{expr} into node"
             end

      SyntaxNode.new(
        type,
        token: expr
      )
    end

    def evaluate_identifier(expr)
      if @variables.keys.include? expr.id.value
        value_token = @variables[expr.id.value]

        return value_token
      end

      diagnostics << "Unknown variable \"#{expr.id.value}\" at #{expr.id.start_printing_position}"
      raise diagnostics.last
    end

    def evaluate_assignment(expr)
      result = evaluate_expr! expr.value

      @variables[expr.id.value] = result
      result
    end

    def evaluate_binary(expr)
      left = evaluate_expr!(expr.left)
      right = evaluate_expr!(expr.right)
      operator = expr.operator

      eval_binary_expr(expr, left, operator, right)
    end

    def evaluate_array(expr)
      evaluated_body = expr.items.map do |item|
        evaluate_expr!(item)
      end

      new_eval_token(
        SyntaxKind::ArrayExpression,
        expr.open_token,
        evaluated_body
      )
    end

    def evaluate_global_scope(expr)
      results = expr.children.map do |subtree|
        evaluate_expr! subtree
      end

      results.last
    end

    def evaluate_sub_expr(expr)
      evaluate_expr! expr.expression
    end

    def evaluate_builtin_function(expr)
      arg_value = evaluate_expr!(expr.args)

      evaluate_builtin(expr.name, arg_value)
    end

    # A fake mid-evaluation token based on @base_token
    # will be unwrapped down the line with recursion
    def new_eval_token(kind, base_token, value)
      Token.new(
        kind,
        base_token.position,
        base_token.text,
        value
      )
    end

    def eval_binary_expr(expr, left, operator, right)
      if left.kind == SyntaxKind::NumberToken &&
         right.kind == SyntaxKind::NumberToken

        left_value = left.value
        right_value = right.value

        if operator.kind == SyntaxKind::EqualityToken
          return SyntaxNode.new(
            SyntaxNodeType::BooleanExpression,
            token: new_eval_token(
              SyntaxKind::BooleanToken,
              left,
              left_value == right_value
            )
          )

        elsif operator.kind == SyntaxKind::InequalityToken
          return SyntaxNode.new(
            SyntaxNodeType::BooleanExpression,
            token: new_eval_token(
              SyntaxKind::BooleanToken,
              left,
              left_value != right_value
            )
          )
        end

        new_eval_token(
          SyntaxKind::NumberToken,
          left,
          apply_numeric_operator(expr, left_value, operator, right_value)
        )
      elsif left.kind == SyntaxKind::StringToken &&
            right.kind == SyntaxKind::StringToken

        if operator.kind == SyntaxKind::PlusToken
          value = left.value + right.value

          return new_eval_token(
            SyntaxKind::StringToken,
            left,
            value
          )
        end

        raise "Operator #{operator.text} is not applicable to strings."
      else
        raise "Operator #{operator.text} is not applicable to \"#{left.value}\" and \"#{right.value}\""
      end
    end

    def apply_numeric_operator(expr, left, operator, right)
      case operator.kind
      when SyntaxKind::PlusToken then left + right
      when SyntaxKind::MinusToken then left - right
      when SyntaxKind::StarToken then left * right
      when SyntaxKind::SlashToken
        denom = right
        denom = right.to_f if right > left || right.is_a?(Float)

        left / denom
      when SyntaxKind::DoubleStarToken then left**right
      else raise "Unexpected binary operator #{expr.operator.kind}".error!
      end
    end

    def evaluate_builtin(name_token, arg_value_token)
      raise "No value provided for builtin function \"#{name_token.value}\" at #{name_token.start_printing_position}" unless arg_value_token

      case name_token.value
      when 'puts' then builtin_puts(arg_value_token)
      when 'print' then builtin_print(arg_value_token)
      else
        raise "Unknown builtin function \"#{name_token.text}\" at #{name_token.start_printing_position}"
      end
    end

    # evaluates the array index token before
    # actually indexing the corresponding item
    def array_index_token(array_token, given_index_token)
      unless array_token.kind == SyntaxKind::ArrayExpression
        raise "Array indexing is only allowed on arrays. Got #{array_token.kind} at #{array_token.start_printing_position}."
      end

      index_token = given_index_token

      if given_index_token.kind == SyntaxKind::IdentifierToken
        index_token = evaluate_expr!(
          SyntaxNode.new(
            SyntaxNodeType::IdentifierExpression,
            id: given_index_token
          )
        )
      end

      index_token
    end

    def evaluate_array_indexing(expr)
      array_token = evaluate_expr!(SyntaxNode.new(SyntaxNodeType::IdentifierExpression, id: expr.array_id))

      index_value = array_index_token(array_token, expr.index).value

      array_token.value[index_value]
    end

    def evaluate_array_indexing_assignment(expr)
      array_token = evaluate_expr!(
        SyntaxNode.new(
          SyntaxNodeType::IdentifierExpression,
          id: expr.array_indexing_expression.array_id
        )
      )

      index_value = array_index_token(array_token, expr.array_indexing_expression.index).value

      array_token.value[index_value] = evaluate_expr!(expr.right)

      array_token
    end

    def evaluate_condition(expr)
      condition = evaluate_expr! expr.condition

      if expr.condition_branches.count > 1
        index = condition.token.value ? 0 : 1

        evaluate_expr!(expr.condition_branches[index])
      elsif condition.token.value
        evaluate_expr! expr.condition_branches.first
      end
    end

    def evaluate_body(expr)
      expr.body_items.map do |subtree|
        evaluate_expr! subtree
      end
    end

    def builtin_puts(arg)
      case arg.kind
      when SyntaxKind::ArrayExpression
        arg.value.each do |sub|
          builtin_puts(sub)
        end
      when SyntaxNodeType::BooleanExpression
        builtin_puts(arg.token)
      else
        puts arg.value
      end
    end

    def builtin_print(arg)
      case arg.kind
      when SyntaxKind::ArrayExpression
        print '['
        arg.value.each do |sub|
          builtin_print(sub)
        end
        print ']'
      when SyntaxNodeType::BooleanExpression
        builtin_print(arg.token)
      else
        print arg.value
      end
    end
  end
end
