# frozen_string_literal: true

module Syntax
  class SyntaxNode
    attr_reader :kind

    def initialize(kind, children)
      @kind = kind
      @children = Array(children)
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
        [],
      )
    end
  end

  class ExpressionSyntax < SyntaxNode
    def initialize(kind, children)
      super
      @children = children
    end

    def debug_print!
      pretty_print_tree self
      nil
    end
  end

  class BinaryExpressionSyntax < ExpressionSyntax
    attr_reader :left, :operator, :right

    def initialize(left, operator, right)
      super(SyntaxKind::BinaryExpression, [left, operator, right])
      @left = left
      @operator = operator
      @right = right
    end
  end

  class NumberExpressionSyntax < ExpressionSyntax
    attr_reader :kind, :token, :is_integer

    def initialize(token)
      super(kind, [token])
      @token = token
      @is_integer = token.value.is_a? Integer
    end
  end

  class StringExpressionSyntax < ExpressionSyntax
    attr_reader :kind, :token

    def initialize(token)
      super(kind, [])
      @token = token
    end
  end

  class ParenthesizedExpressionSyntax < ExpressionSyntax
    attr_reader :kind, :open_token, :expression, :closed_token

    def initialize(open_token, expression, closed_token)
      super(SyntaxKind::ParenthesizedExpression, [open_token, expression, closed_token])
      @open_token = open_token
      @expression = expression
      @closed_token = closed_token
    end
  end

  class IdentifierExpressionSyntax < ExpressionSyntax
    attr_reader :id

    def initialize(id)
      super(SyntaxKind::IdentifierToken, [id])
      @id = id
    end
  end

  class AssignmentExpressionSyntax < ExpressionSyntax
    attr_reader :id, :value

    def initialize(id, value)
      super(SyntaxKind::AssignmentToken, [id, value])
      @id = id
      @value = value
    end
  end

  class BuiltinFunctionSyntax < ExpressionSyntax
    attr_reader :name, :args

    def initialize(name, args)
      super(SyntaxKind::BuiltinFunction, [name, args])
      @name = name
      @args = args
    end
  end
end
