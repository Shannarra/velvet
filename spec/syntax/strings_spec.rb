# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing variables', type: :feature do
  describe 'creating a string' do
    context 'when it\'s just a plain token' do
      let(:text) do
        <<~TEXT
          "hello"
          'world'
        TEXT
      end

      it 'creates strings with single and double quotes' do
        expect do
          perform_evaluation!(text)
        end.not_to raise_error
      end
    end

    context 'when used as a variable' do
      shared_examples 'evaluates as a string variable' do
        it 'evaluates correctly' do
          variables = {}
          expect do
            variables = perform_evaluation!(text).root.variables
          end.not_to raise_error

          expect(variables.count).to eq 1
          expect(variables['greeting']).to have_attributes(value: 'Hello, world!', kind: Syntax::SyntaxKind::StringToken)
        end
      end

      context 'when using single-quote string' do
        let(:text) do
          <<~TEXT
            greeting = 'Hello, world!'
          TEXT
        end

        it_behaves_like 'evaluates as a string variable'
      end

      context 'when using double-quote string' do
        let(:text) do
          <<~TEXT
            greeting = "Hello, world!"
          TEXT
        end

        it_behaves_like 'evaluates as a string variable'
      end
    end
  end

  describe 'using strings' do
    context 'when applying string operators' do
      let(:text_with_concat) do
        <<~TEXT
          hello = 'Hello, '
          world = "world!"

          greeting = hello + world
        TEXT
      end

      it 'concatenates the string correctly' do
        variables = {}
        expect do
          variables = perform_evaluation!(text_with_concat).root.variables
        end.not_to raise_error

        expect(variables.count).to eq 3
        expect(variables['hello']).to have_attributes(value: 'Hello, ', kind: Syntax::SyntaxKind::StringToken)
        expect(variables['world']).to have_attributes(value: 'world!', kind: Syntax::SyntaxKind::StringToken)
        expect(variables['greeting']).to have_attributes(value: 'Hello, world!', kind: Syntax::SyntaxKind::StringToken)
      end
    end

    context 'when using undefined string operators' do
      it 'raises errors for EACH operator that is NOT applicable' do
        Syntax::Constants::Values::OPERATORS[1..4].each do |operator|
          text = <<~TEXT
            hello = 'Hello, '
            world = "world!"

            greeting = hello #{operator} world
          TEXT

          expect do
            perform_evaluation!(text)
          end.to raise_error(RuntimeError, "Operator #{operator} is not applicable to strings.")
        end
      end
    end
  end

  describe 'when mixing strings with other variables' do
    context 'trying to concatenate or perform other operator on string and non-string' do
      it 'raises errors for EACH operator and both sides' do
        Syntax::Constants::Values::OPERATORS[..4].each do |operator|
          number_value = rand(1..100)
          text = <<~TEXT
            hello = 'Hello, '
            number = #{number_value}

            greeting = hello #{operator} number
          TEXT

          expect do
            perform_evaluation!(text)
          end.to raise_error(
            RuntimeError,
            "Operator #{operator} is not applicable to \"Hello, \" and \"#{number_value}\""
          )
        end
      end
    end
  end
end
