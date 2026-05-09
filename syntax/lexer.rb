# frozen_string_literal: true

require_relative 'token'

module Syntax
  class Lexer # rubocop:disable Syntax/ClassLength
    attr_reader :diagnostics

    def initialize(text)
      @text = text
      @diagnostics = []
      @ip = 0
      @position = Position.new
    end

    def lex! # rubocop:disable Metrics/MethodLength
      return Token.new(SyntaxKind::EOFToken, @position.dup, '\0', nil) if @ip >= @text.length

      return handle_string if %w[' "].include?(current)

      return handle_comment if current == '#'

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
             when '%'
               SyntaxKind::ModuloToken
             when '('
               SyntaxKind::OpenParenthesisToken
             when ')'
               SyntaxKind::CloseParenthesisToken
             when '['
               SyntaxKind::OpenBracketToken
             when ']'
               SyntaxKind::CloseBracketToken
             when ','
               SyntaxKind::CommaToken
             when '<'
               SyntaxKind::LessThanToken
             when '>'
               SyntaxKind::GreaterThanToken
             when '!'
               raise "Unexpected ! found at #{@position}" unless @text[@ip + 1] == '='

               get_next
               SyntaxKind::InequalityToken
             when '&'
               raise 'unexpected &' unless @text[@ip + 1] == current

               get_next
               SyntaxKind::BooleanAND
             when '|'
               raise 'unexpected |' unless @text[@ip + 1] == current

               get_next
               SyntaxKind::BooleanOR
             when '='
               if @text[@ip + 1] == current
                 get_next
                 SyntaxKind::EqualityToken
               else
                 SyntaxKind::AssignmentToken
               end
             else
               token = ''
               until Constants::Values::NON_ALPHA.include?(current)
                 token += current
                 get_next
               end

               if Constants::Builtin::NAMES.include?(token)
                 return Token.new(
                   SyntaxKind::BuiltinFunction,
                   @position.dup,
                   token,
                   token
                 )
               end

               return handle_keyword(token) if Constants::Values::KEYWORDS.include?(token)

               return Token.new(SyntaxKind::IdentifierToken, @position.dup, token, token)
             end

      old_value = current
      get_next
      return Token.new(type, @position.dup, old_value, nil) if type

      @diagnostics << "Bad character input: '#{current}'"
      Token.new(SyntaxKind::BadToken, @position.dup, @text[@ip - 1], nil)
    end

    private

    def handle_keyword(token)
      kword_type =  case token
                    when 'if'
                      SyntaxKind::KWRD_IF
                    when 'else'
                      SyntaxKind::KWRD_ELSE
                    when 'do'
                      SyntaxKind::KWRD_DO
                    when 'end'
                      SyntaxKind::KWRD_END
                    when 'true'
                      SyntaxKind::KWRD_TRUE
                    when 'false'
                      SyntaxKind::KWRD_FALSE
                    when 'from'
                      SyntaxKind::KWRD_FROM
                    when 'to'
                      SyntaxKind::KWRD_TO
                    when 'step'
                      SyntaxKind::KWRD_STEP
                    when 'break'
                      SyntaxKind::KWRD_BREAK
                    else
                      raise "Unknown keyword \"#{token}\""
                    end

      Token.new(kword_type, @position.dup, token, nil)
    end

    def handle_comment
      start = @ip
      get_next while current != "\n" && current != '\0'

      value = @text[start..(@ip - 1)]
      Token.new(SyntaxKind::CommentToken, Position.new(@position.row, start), value, value)
    end

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

      Token.new(SyntaxKind::NumberToken, @position.dup, text, num)
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

        get_next(2) while current == initial
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

    def handle_string
      string_termination_token = current
      get_next

      start = @ip

      get_next while current != string_termination_token

      text = @text[start...@ip]
      get_next

      Token.new(SyntaxKind::StringToken, @position.dup, text, text)
    end

    def current
      return '\0' if @ip >= @text.length

      @text[@ip]
    end

    def get_next(forward_step = 1)
      if current == "\n"
        @position.nextline!
      else
        @position.move_forward!(forward_step)
      end

      @ip += 1
    end
  end
end
