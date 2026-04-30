# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing variables', type: :feature do
  describe 'using a built-in function' do
    describe 'printing' do
      let(:text) do
        <<~TEXT
          first = "John "
          last = 'Pork'

          puts first + last

          print first + last
        TEXT
      end

      it 'prints newlines with "puts" and no newline with "print"' do
        expect do
          perform_evaluation!(text)
        end.to output("John Pork\nJohn Pork").to_stdout
      end
    end
  end
end
