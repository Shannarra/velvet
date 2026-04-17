# frozen_string_literal: true

require_relative 'parser'
require_relative 'node'

module Syntax
  # !important! BadToken should be taken as a default token type!
  SyntaxKind = enum %w[
    BadToken

    NumberToken
    PlusToken
    MinusToken
    StarToken
    DoubleStarToken
    SlashToken
    OpenParenthesisToken
    CloseParenthesisToken
    AssignmentToken

    ParenthesizedExpression
    NumberExpression
    BinaryExpression

    CommentToken
    EOFToken

    TabToken
    NewlineToken
    WhitespaceToken

    IdentifierToken
  ]

  module Constants
    module Values
      SPACES = [' ', "\n", "\t"].freeze
      OPERATORS = %w[+ - * ** / ( ) =].freeze
      COMMENT = '#'
      EOF = '\0'

      NON_ALPHA = [*SPACES, *OPERATORS, EOF].freeze
    end

    module Kinds
      SPACES = [SyntaxKind::TabToken, SyntaxKind::NewlineToken, SyntaxKind::WhitespaceToken].freeze

      OPERATORS = [
        SyntaxKind::PlusToken,
        SyntaxKind::MinusToken,
        SyntaxKind::StarToken,
        SyntaxKind::DoubleStarToken,
        SyntaxKind::SlashToken,
        SyntaxKind::OpenParenthesisToken,
        SyntaxKind::CloseParenthesisToken,
        SyntaxKind::AssignmentToken
      ].freeze

      COMMENT = SyntaxKind::CommentToken
      EOF = SyntaxKind::EOFToken

      VOID = [*SPACES, COMMENT].freeze

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
      def global_scope
        SyntaxTree.new([], GlobalScope.new, '\0')
      end

      def parse(text)
        global_scope = SyntaxTree.global_scope

        parser = Parser.new(text, global_scope)
        parser.parse!

        puts parser.diagnostics unless parser.diagnostics.empty?

        global_scope
      end
    end
  end
end
