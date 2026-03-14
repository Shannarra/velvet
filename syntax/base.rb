# frozen_string_literal: true

require_relative 'parser'
require_relative 'node'

module Syntax
  SyntaxKind = enum %w[
    NumberToken
    WhitespaceToken
    PlusToken
    MinusToken
    StarToken
    DoubleStarToken
    SlashToken
    OpenParenthesisToken
    CloseParenthesisToken
    BadToken
    EOFToken
    NumberExpression
    BinaryExpression
    ParenthesizedExpression

    NewlineToken
    TabToken

    AssignmentToken
    IdentifierToken
  ]

  module Constants
    module Values
      SPACES = [' ', "\n", "\t"].freeze
      OPERATORS = %w[+ - * / ( ) =].freeze
      EOF = '\0'

      NON_ALPHA = [*SPACES, *OPERATORS, EOF].freeze
    end
  end

  class SyntaxTree
    attr_reader :diagnostics, :root, :eof_token

    def initialize(diagnostics, root, eof_token)
      @diagnostics = diagnostics.flatten
      @root = root
      @eof_token = eof_token
    end

    class << self
      def parse(text)
        parser = Parser.new(text)

        parser.parse
      end
    end
  end
end
