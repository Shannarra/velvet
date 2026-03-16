# frozen_string_literal: true

require_relative 'node'

module Syntax
  class Token < SyntaxNode
    attr_reader :position, :text, :value

    def initialize(kind, position, text, value)
      super(kind, []) # don't pass Token properties as children

      @position = position
      @text = text
      @value = value
    end

    def print_position
      col_pos = position.col - (text&.length || 0)

      "#{position.row + 1}:#{col_pos + 1}"
    end

    def inspect
      "<Token:#{kind}, text = \"#{text}\" (value \"#{value}\") at #{print_position}>"
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
      "#{@row}:#{@col}"
    end
  end
end
