# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing variables', type: :feature do
  describe 'creating an array' do
    context 'when it\'s just a plain token' do
      let(:text) do
        <<~TEXT
          ['I', "am", 'an', "array"]
        TEXT
      end

      it 'creates an array of strings with single and double quotes' do
        expect do
          perform_evaluation!(text)
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
        variables = {}

        expect do
          variables = perform_evaluation!(text).root.variables
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
        variables = {}

        expect do
          variables = perform_evaluation!(text).root.variables
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

    context 'when indexing array with itself' do
      let(:text) do
        <<~TEXT
          simple_array = [1, 2, 3, 4, 5]

          print "Array item = "
          puts simple_array[simple_array[simple_array[simple_array[simple_array[0]]]]]
        TEXT
      end

      it 'evaluates indexing correctly' do
        expect do
          perform_evaluation!(text)
        end.to output("Array item = 5\n").to_stdout
      end
    end

    context 'when assignment indexing' do
      let(:text) do
        <<~TEXT
          array = ['I', "am", 'an', "array"]

          index = 2**3-2*3

          array[index] = 'ABOBA'
        TEXT
      end

      it 'creates an array of strings with single and double quotes' do
        variables = {}

        expect do
          variables = perform_evaluation!(text).root.variables
        end.not_to raise_error

        expect(variables['index']).to have_attributes(value: 2, kind: Syntax::SyntaxKind::NumberToken)

        expect(variables['array'].value).to match_array(
          [
            have_attributes(value: 'I', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'am', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'ABOBA', kind: Syntax::SyntaxKind::StringToken),
            have_attributes(value: 'array', kind: Syntax::SyntaxKind::StringToken)
          ]
        )
      end
    end

    context 'when having a syntax error' do
      let(:text) do
        <<~TEXT
          array = ['I', "am" 'an', "array"]

          index = 2**3-2*3

          array[index] = 'ABOBA'
        TEXT
      end

      it 'creates an array of strings with single and double quotes' do
        scope = nil

        expect do
          scope = perform_evaluation!(text)
        end.to raise_error(RuntimeError, 'Unexpected token <StringToken>. Expected <CommaToken> at 1:23')

        expect(scope&.root&.variables).to be_nil
      end
    end
  end
end
