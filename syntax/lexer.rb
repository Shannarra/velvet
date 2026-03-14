# frozen_string_literal: true

require_relative 'token'

module Syntax
  class Lexer
    attr_reader :diagnostics

    def initialize(text)
      @text = text
      @diagnostics = []
      @ip = 0
      @position = Position.new
    end

    def lex!
      return Token.new(SyntaxKind::EOFToken, @position.dup, '\0', nil) if @ip >= @text.length

      return handle_numeric if current.numeric?

      return handle_whitetext if [' ', "\n", "\t"].include? current

      type = case current
             when '+'
               SyntaxKind::PlusToken
             when '-'
               SyntaxKind::MinusToken
             when '*'
               SyntaxKind::StarToken
             when '/'
               SyntaxKind::SlashToken
             when '('
               SyntaxKind::OpenParenthesisToken
             when ')'
               SyntaxKind::CloseParenthesisToken
             when '='
               SyntaxKind::AssignmentToken
             else
               token = ''
               until [' ', '=', '\0'].include?(current)
                 token += current
                 get_next
               end

               return Token.new(SyntaxKind::IdentifierToken, @position.dup, token, token)
             end

      return Token.new(type, get_next, current, nil) if type

      @diagnostics << "Bad character input: '#{current}'"
      Token.new(SyntaxKind::BadToken, get_next, @text[@ip - 1], nil)
    end

    private

    def handle_numeric
      start = @ip

      get_next while current.numeric?

      text = @text[start...@ip]
      num = nil

      begin
        num = if current == '.'
                get_next
                get_next while current.numeric?

                text = @text[start...@ip]
                Float(text)
              else
                Integer(text)
              end
      rescue ArgumentError
        @diagnostics << "[ERROR] \"#{text}\" is not a valid number!"
      end

      Token.new(SyntaxKind::NumberToken, start, text, num)
    end

    def handle_whitetext
      case current
      when ' '
        start = @ip
        get_next while current == ' '

        text = @text[start...@ip]
        Token.new(SyntaxKind::WhitespaceToken, @position.dup, text, nil)
      when "\n"
        initial = current
        start = @ip

        get_next while current == initial
        text = @text[start..@ip]
        Token.new(SyntaxKind::NewlineToken, @position.dup, text, nil)
      when "\t"
        initial = current
        start = @ip

        get_next while current == initial
        text = @text[start..@ip]
        Token.new(SyntaxKind::TabToken, @position.dup, text, nil)
      else
        raise "Unhandled whitespace character #{current}".error!
      end
    end

    def current
      return '\0' if @ip >= @text.length

      @text[@ip]
    end

    # rubocop:disable Naming/AccessorMethodName
    def get_next
      @ip += 1
      @position.move_forward!(1)
    end
    # rubocop:enable Naming/AccessorMethodName
  end
end
