# frozen_string_literal: true

module Syntax
  class Evaluator # rubocop:disable Metrics/ClassLength
    attr_reader :diagnostics

    def initialize(root, variables, parent_scope)
      @root = root
      @variables = variables
      @diagnostics = []
      @parent_scope = parent_scope
    end

    def eval!
      evaluate_expr! @root
    end

    def self.eval_tree!(tree, variables)
      diagnostics = []
      tree.root.children.each do |sub|
        ev = new(sub.root, variables, tree.scope)

        ev.eval!

        diagnostics << ev.diagnostics
      end

      diagnostics
    end

    private

    def evaluate_expr!(expr)
      return expr.token if expr.is_a? NumberExpressionSyntax
      return expr.token if expr.is_a? StringExpressionSyntax

      if expr.is_a? IdentifierExpressionSyntax
        if @variables.keys.include? expr.id.value
          value_token = @variables[expr.id.value]

          return value_token
        end

        diagnostics << "Unknown variable \"#{expr.id.value}\" at #{expr.id.start_printing_position}"
        raise diagnostics.last
      end

      if expr.is_a? AssignmentExpressionSyntax
        result = evaluate_expr! expr.value

        @variables[expr.id.value] = result
        return result
      end

      if expr.is_a? BinaryExpressionSyntax
        left = evaluate_expr!(expr.left)
        right = evaluate_expr!(expr.right)
        operator = expr.operator

        return eval_binary_expr(left, operator, right)
      end

      return evaluate_expr! expr.expression if expr.is_a? ParenthesizedExpressionSyntax

      if expr.is_a? BuiltinFunctionSyntax
        arg_value = evaluate_expr!(expr.args)

        return evaluate_builtin(expr.name, arg_value)
      end

      if expr.is_a? ArrayExpressionSyntax
        evaluated_body = expr.items.map do |item|
          evaluate_expr!(item)
        end

        return new_eval_token(
          SyntaxKind::ArrayExpression,
          expr.open_token,
          evaluated_body
        )
      end

      return evaluate_array_indexing(expr) if expr.is_a? ArrayIndexingExpressionSyntax

      return evaluate_array_indexing_assignment(expr) if expr.is_a? ArrayIndexingAssignmentExpressionSyntax

      if expr.is_a?(GlobalScope)
        results = expr.children.map do |subtree|
          evaluate_expr! subtree
        end

        return results.last
      end

      diagnostics << "Unexpected node \"#{expr.is_a?(Token) ? expr.kind : expr}\""

      raise @diagnostics.last
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

    def eval_binary_expr(left, operator, right)
      if left.kind == SyntaxKind::NumberToken &&
         right.kind == SyntaxKind::NumberToken

        left_value = left.value
        right_value = right.value

        new_eval_token(
          SyntaxKind::NumberToken,
          left,
          apply_numeric_operator(left_value, operator, right_value)
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

    def apply_numeric_operator(left, operator, right)
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

      index_token = evaluate_expr!(NumberExpressionSyntax.new(given_index_token))

      index_token = evaluate_expr!(IdentifierExpressionSyntax.new(index_token)) if index_token.kind == SyntaxKind::IdentifierToken

      index_token
    end

    def evaluate_array_indexing(expr)
      array_token = evaluate_expr!(IdentifierExpressionSyntax.new(expr.array_id))

      index_token = array_index_token(array_token, expr.index)

      array_token.value[index_token.value]
    end

    def evaluate_array_indexing_assignment(expr)
      array_token = evaluate_expr!(IdentifierExpressionSyntax.new(expr.array_indexing_expression.array_id))

      index_token = array_index_token(array_token, expr.array_indexing_expression.index)

      array_token.value[index_token.value] = evaluate_expr!(expr.right)

      array_token
    end

    def builtin_puts(arg)
      case arg.kind
      when SyntaxKind::ArrayExpression
        arg.value.each do |sub|
          builtin_puts(sub)
        end
      else
        value = arg.is_a?(ExpressionSyntax) ? evaluate_expr!(arg).value : arg.value
        puts value
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
      else
        value = arg.value
        print value
      end
    end
  end
end
