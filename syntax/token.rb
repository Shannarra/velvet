# frozen_string_literal: true

require_relative 'node'

module Syntax
  class Token < SyntaxNode
    attr_reader :position, :text, :value

    def initialize(kind, position, text, value)
      super(kind, children: []) # don't pass Token properties as children

      @position = position
      @text = text
      @value = value

      if kind == SyntaxKind::KWRD_TRUE
        @value = true
      elsif kind == SyntaxKind::KWRD_FALSE
        @value = false
      end
    end

    def start_printing_position
      col = position.col - text.length

      "#{position.row + 1}:#{col}"
    end

    def inspect
      "<Token:#{kind}, text = \"#{text}\" (value \"#{value}\") at #{position}>"
    end

    def to_s
      inspect
    end
  end

  class Position
    attr_accessor :row, :col

    def initialize(row = 0, col = 0)
      @row = row
      @col = col
    end

    def move_forward!(offset)
      @col += offset
      self
    end

    def nextline!
      old = self
      @col = 0
      @row += 1
      old
    end

    def to_s
      inspect
    end

    def inspect
      "#{@row + 1}:#{@col}"
    end
  end
end
