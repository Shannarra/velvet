# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing variables', type: :feature do
  let(:evaluator) { Syntax::Evaluator }
  let(:variables) { {} }

  before do
    @eval = ->(root, variables) { evaluator.eval_tree!(root, variables) }
  end

  describe 'when reading a file' do
    context 'with multiline expressions and comments' do
      let(:filename) { './spec/fixtures/multiline_numbers_with_comments.txt' }
      let(:expected_result) { -277_695.639_560_439_57 }

      it 'parses the file correctly and gets the correct result' do
        content = File.read(filename)

        @eval.call(Syntax::SyntaxTree.parse(content), variables)

        expect(variables['result']).to eq expected_result
      end
    end

    context 'with a multiline expression AND a SYNTAX ERROR' do
      let(:filename) { './spec/fixtures/file_with_syntax_error.txt' }

      it 'parses the file correctly RAISES an error' do
        expect do
          content = File.read(filename)
          @eval.call(Syntax::SyntaxTree.parse(content), variables)
        end.to raise_error(RuntimeError, 'Unexpected token "aboba" (IdentifierToken) found at 3:12')
      end
    end
  end
end
