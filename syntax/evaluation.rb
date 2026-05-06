# frozen_string_literal: true

module Syntax
  class Evaluator # rubocop:disable Metrics/ClassLength
    attr_reader :diagnostics

    def initialize(root, parent_scope)
      @root = root
      @diagnostics = []
      @parent_scope = parent_scope.parent
      @current_scope = parent_scope

      @eval_iter = 0
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
      KWRD_FALSE: :wrap_to_node,
      ForLoopExpression: :evaluate_from_loop
    }.freeze

    private

    def evaluate_expr!(expr)
      @eval_iter += 1

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
      # check current scope for existing variable name
      if @current_scope.variables.keys.include? expr.id.value
        value_token = @current_scope.variables[expr.id.value]

        return value_token
      end

      # if not found - check all parent scopes until found
      variable = deep_search_parent_variable_for!(expr)

      return variable if variable

      diagnostics << "Unknown variable \"#{expr.id.value}\" at #{expr.id.start_printing_position}"
      raise diagnostics.last
    end

    # Digs through all parent scopes in the tree
    # until we find a variable matching the given expression
    #
    # If the variable is found - we return its value
    # If @param return_scope is provided we return the entire scope
    # where the value was found instead.
    def deep_search_parent_variable_for!(expr, parent: nil, return_scope: false)
      parent ||= @parent_scope

      until parent.nil?
        if parent.variables.keys.include? expr.id.value
          value_token = parent.variables[expr.id.value]

          return parent if return_scope

          return value_token
        end
        parent = parent.parent
      end
    end

    def evaluate_assignment(expr)
      result = evaluate_expr! expr.value

      scope = deep_search_parent_variable_for!(expr, return_scope: true)

      if scope
        scope.variables[expr.id.value] = result
      else
        @current_scope.variables[expr.id.value] = result
      end

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

        return apply_boolean_operator(expr, left, operator, right) if Constants::Kinds::BOOLEAN_OPERATORS.include?(operator.kind)

        raise "Operator #{operator.kind} is not applicable to numbers" unless Constants::Kinds::NUMERIC_OPERATORS.include?(operator.kind)

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
      elsif left.kind == SyntaxNodeType::BooleanExpression &&
            right.kind == SyntaxNodeType::BooleanExpression

        unless Constants::Kinds::BOOLEAN_OPERATORS.include?(operator.kind)
          raise "Operator #{operator.kind} is not applicable to boolean expressions"
        end

        apply_boolean_operator(expr, left.token, operator, right.token)
      else
        raise "Operator #{operator.text} is not applicable to \"#{left.value}\" (#{left.kind}) and \"#{right.value}\" (#{right.kind})"
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
      when SyntaxKind::ModuloToken then left % right
      else raise "Unexpected binary operator #{expr.operator.kind}".error!
      end
    end

    def apply_boolean_operator(expr, left, operator, right)
      value = case operator.kind
              when SyntaxKind::LessThanToken then left.value < right.value
              when SyntaxKind::GreaterThanToken then left.value > right.value
              when SyntaxKind::EqualityToken then left.value == right.value
              when SyntaxKind::InequalityToken then left.value != right.value
              when SyntaxKind::BooleanAND then left.value && right.value
              when SyntaxKind::BooleanOR then left.value || right.value
              else raise "Unexpected binary operator #{expr.operator.kind}".error!
              end

      SyntaxNode.new(
        SyntaxNodeType::BooleanExpression,
        token: new_eval_token(
          SyntaxKind::BooleanToken,
          left,
          value
        )
      )
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

      evaluate_expr! index_token
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

      unless condition.kind == SyntaxNodeType::BooleanExpression
        raise "Condition MUST be a boolean expression.
Got \"#{condition.text}\" (#{condition.kind}) at #{condition.start_printing_position}"
      end

      branch = if expr.condition_branches.count > 1
                 index = condition.token.value ? 0 : 1

                 expr.condition_branches[index]
               elsif condition.token.value
                 expr.condition_branches.first
               end

      return if branch.nil?

      within_scope(name: "Conditional scope #{@eval_iter}") do
        branch
      end
    end

    def evaluate_from_loop(expr)
      upper_bound_token = evaluate_expr!(expr.upper_bound)

      parent = @current_scope

      from_loop_scope = Scope.new({}, parent, "FROM loop scope #{@eval_iter}")

      Evaluator.new(expr.lower_assignment, from_loop_scope).eval!

      lower_bound_token = from_loop_scope.variables[expr.lower_assignment.id.value]

      lower_bound_token = deep_search_parent_variable_for!(expr.lower_assignment, parent:) if lower_bound_token.nil?

      while lower_bound_token.value < upper_bound_token.value
        within_scope(scope: from_loop_scope) do
          expr.loop_body
        end
        lower_bound_token.value += 1
      end

      @current_scope = parent
    end

    def evaluate_body(expr)
      expr.body_items.map do |subtree|
        evaluate_expr! subtree
      end
    end

    def within_scope(scope: nil, parent: @current_scope, name: 'idk', &block)
      scope ||= Scope.new({}, parent, name)

      branch = yield block

      result = Evaluator.new(branch, scope).eval!

      result.first
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
