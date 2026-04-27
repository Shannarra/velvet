# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing variables', type: :feature do
  let(:evaluator) { Syntax::Evaluator }
  let(:variables) { {} }

  before do
    @eval = ->(root, variables) { evaluator.eval_tree!(root, variables) }
  end

  describe 'creating an array' do
    context 'when it\'s just a plain token' do
      let(:text) do
        <<~TEXT
          ['I', "am", 'an', "array"]
        TEXT
      end

      it 'creates an array of strings with single and double quotes' do
        expect do
          @eval.call(Syntax::SyntaxTree.parse(text), variables)
        end.not_to raise_error
      end
    end

    context 'when used as a variable' do
      let(:text) do
        <<~TEXT
          array = ['I', "am", 'an', "array"]
        TEXT
      end

      it 'creates an array of strings with single and double quotes' do
        expect do
          @eval.call(Syntax::SyntaxTree.parse(text), variables)
        end.not_to raise_error

        expect(variables['array'].value).to match_array(
          [
            have_attributes(value: 'I', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'am', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'an', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'array', kind: Syntax::SyntaxKind::StringToken)
          ]
        )
      end
    end
  end

  describe 'using an array' do
    context 'when plain indexing' do
      let(:text) do
        <<~TEXT
          array = ['I', "am", 'an', "array"]

          index = 2**3-2*3

          item = array[index]
        TEXT
      end

      it 'creates an array of strings with single and double quotes' do
        expect do
          @eval.call(Syntax::SyntaxTree.parse(text), variables)
        end.not_to raise_error

        expect(variables['array'].value).to match_array(
          [
            have_attributes(value: 'I', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'am', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'an', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'array', kind: Syntax::SyntaxKind::StringToken)
          ]
        )
        expect(variables['index']).to have_attributes(value: 2, kind: Syntax::SyntaxKind::NumberToken)
        expect(variables['item']).to have_attributes(value: 'an', kind: Syntax::SyntaxKind::StringToken)
      end
    end
  end
end
