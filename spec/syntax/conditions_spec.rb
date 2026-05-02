# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing conditions', type: :feature do
  describe 'using booleans' do
    describe 'when using boolean values' do
      context 'when multipple branches have ONLY ONE truthy value' do
        let(:text) do
          <<~TEXT
            first = true
            second = false

            if first && second do
            	 puts "both are true"
            else if first || second do
            	 puts "at least one is true"
            else
            	puts "Neither first or second is true :("
            end
          TEXT
        end

        it 'evaluates that JUST ONE branch is true' do
          expect do
            perform_evaluation!(text)
          end.to output("at least one is true\n").to_stdout
        end
      end

      context 'when multipple branches have truthy valueS' do
        let(:text) do
          <<~TEXT
            first = true
            second = true

            if first && second do
            	 puts "both are true"
            else if first || second do
            	 puts "at least one is true"
            else
            	puts "Neither first or second is true :("
            end
          TEXT
        end

        it 'evaluates that JUST ONE branch is true' do
          expect do
            perform_evaluation!(text)
          end.to output("both are true\n").to_stdout
        end
      end
    end

    context 'when comparing values' do
      let(:text) do
        <<~TEXT
          a = 10
          b = 20

          a_plus_10 = a + 10

          does_a_eq_b = a == b
          does_a_plus_10_eq_b = a_plus_10 == b
          a_isnt_b = a != b
        TEXT
      end

      it 'performs the boolean comparisons correctly' do
        variables = perform_evaluation!(text).root.variables

        expect(variables['does_a_eq_b'].token).to have_attributes(value: false, kind: Syntax::SyntaxKind::BooleanToken)
        expect(variables['does_a_plus_10_eq_b'].token).to have_attributes(value: true, kind: Syntax::SyntaxKind::BooleanToken)
        expect(variables['a_isnt_b'].token).to have_attributes(value: true, kind: Syntax::SyntaxKind::BooleanToken)
      end
    end
  end

  describe 'using conditions' do
    describe 'single-branch conditions' do
      context 'when condition IS satisfied' do
        let(:text) do
          <<~TEXT
            a = 35
            b = 34

            if a + b == 69 do
               puts "Nice!"
            end

            puts "I live outside the condition"
          TEXT
        end

        it 'executes the condition' do
          expect do
            perform_evaluation!(text)
          end.to output("Nice!\nI live outside the condition\n").to_stdout
        end
      end

      context 'when condition is NOT satisfied' do
        let(:text) do
          <<~TEXT
            a = 35
            b = 34

            if a + b != 69 do
               puts "Nice!"
            end

            puts "I live outside the condition"
          TEXT
        end

        it 'executes the condition' do
          expect do
            perform_evaluation!(text)
          end.to output("I live outside the condition\n").to_stdout
        end
      end
    end

    describe 'two-branch conditions' do
      context 'when condition IS satisfied' do
        let(:text) do
          <<~TEXT
            a = 35
            b = 34

            if a + b == 69 do
               puts "Nice!"
            else
              puts "NOT nice at all ;("
            end

            puts "I live outside the condition"
          TEXT
        end

        it 'executes the condition' do
          expect do
            perform_evaluation!(text)
          end.to output("Nice!\nI live outside the condition\n").to_stdout
        end
      end

      context 'when condition is NOT satisfied' do
        let(:text) do
          <<~TEXT
            a = 35
            b = 34

            if a + b != 69 do
               puts "Nice!"
            else
              puts "NOT nice at all ;("
            end

            puts "I live outside the condition"
          TEXT
        end

        it 'executes the condition' do
          expect do
            perform_evaluation!(text)
          end.to output("NOT nice at all ;(\nI live outside the condition\n").to_stdout
        end
      end
    end

    describe 'multi-branch conditions' do
      context 'when any condition IS satisfied' do
        let(:text) do
          <<~TEXT
            if 1 == 3 do
            	 puts "1 ?= 3???"
            else if 2 == 3 do
            	 puts "2 ?= 3???"
            else if 3 == 3 do
            	 puts "3 does, in fact, equal 3 :)"
            else
            	 puts "This should have never been printed."
            end

            puts "I live outside the condition"
          TEXT
        end

        it 'executes the branch that satisfies the condition' do
          expect do
            perform_evaluation!(text)
          end.to output("3 does, in fact, equal 3 :)\nI live outside the condition\n").to_stdout
        end
      end

      context 'when condition is NOT satisfied' do
        let(:text) do
          <<~TEXT
            if 1 == 3 do
            	 puts "1 ?= 3???"
            else if 2 == 3 do
            	 puts "2 ?= 3???"
            else if 11 == 3 do
            	 puts "11 ?= 3??"
            else
            	 puts "None of the above."
            end

            puts "I live outside the condition"
          TEXT
        end

        it 'executes the condition' do
          expect do
            perform_evaluation!(text)
          end.to output("None of the above.\nI live outside the condition\n").to_stdout
        end
      end
    end
  end
end
