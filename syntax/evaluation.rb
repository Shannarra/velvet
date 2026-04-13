# frozen_string_literal: true

module Syntax
  class Evaluator
    attr_reader :diagnostics

    def initialize(root, variables)
      @root = root
      @variables = variables
      @diagnostics = []
    end

    def eval!
      evaluate_expr! @root
    end

    def self.eval_tree!(tree, variables)
      diagnostics = []
      tree.root.children.each do |sub|
        ev = new(sub.root, variables)

        ev.eval!

        diagnostics << ev.diagnostics
      end

      diagnostics
    end

    private

    def evaluate_expr!(expr)
      if expr.is_a? NumberExpressionSyntax
        value = expr.token.value

        return expr.is_integer ? Integer(value) : Float(value)
      end

      if expr.is_a? IdentifierExpressionSyntax
        return @variables[expr.id.value] if @variables.keys.include? expr.id.value

        diagnostics << "Unknown variable \"#{expr.id.value}\" on line #{expr.id.position.row + 1}"
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

        case expr.operator.kind
        when SyntaxKind::PlusToken then return left + right
        when SyntaxKind::MinusToken then return left - right
        when SyntaxKind::StarToken then return left * right
        when SyntaxKind::SlashToken
          denom = right
          denom = right.to_f if right > left || right.is_a?(Float)

          return left / denom
        when SyntaxKind::DoubleStarToken then return left**right
        else raise "Unexpected binary operator #{expr.operator.kind}".error!
        end
      end

      return evaluate_expr! expr.expression if expr.is_a? ParenthesizedExpressionSyntax

      if expr.is_a?(GlobalScope)
        results = expr.children.map do |subtree|
          evaluate_expr! subtree
        end

        return results.last
      end

      diagnostics << "Unexpected node \"#{expr.is_a?(Token) ? expr.kind : expr}\""
    end
  end
end
