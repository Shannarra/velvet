# frozen_string_literal: true

require 'spec_helper'

require_relative 'shared_examples'

RSpec.describe 'Testing while loops', type: :feature do
  describe 'using while loops' do
    context 'when printing the numbers from 1 to 10' do
      let(:text) do
        <<~TEXT
          i = 0

          while i < 10 do
            print i

            i = i + 1
          end
        TEXT
      end

      it_behaves_like 'prints numbers sequentially'
    end

    context 'when summing the numbers from 1 to 10' do
      let(:text) do
        <<~TEXT
          sum = 0
          i = 0
          while i < 10 do
            sum = sum + i

            i = i + 1
          end

          puts sum
        TEXT
      end

      it_behaves_like 'sums numbers from 1 to 10'
    end

    context 'when getting the product of an array' do
      let(:array) do
        Array.new(rand(20)) { rand(2..100) }
      end

      let(:text) do
        <<~TEXT
          array = #{array}
          length = #{array.length}

          product = 1

          i = 0

          while i < length do
            product = product * array[i]

            i = i + 1
          end

          puts product
        TEXT
      end

      it_behaves_like 'calculates product of an array'
    end

    context 'when using "break"' do
      context 'when no tokens after "break"' do
        let(:text) do
          <<~TEXT
            i = 0

            while true do
              i = i + 1

              puts i

              if i == 10 do
                 puts 'Breaking!'
                 break
              end
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to output("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\nBreaking!\n").to_stdout
        end
      end

      context 'when there are tokens after "break"' do
        let(:text) do
          <<~TEXT
            i = 0

            while true do
              i = i + 1

              puts i

              if i == 10 do
                 puts 'Breaking!'
                 break

                 puts 'I will NEVER eval!'
              end
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to output("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\nBreaking!\n").to_stdout
        end
      end
    end
  end

  context 'misc cases' do
    describe 'when the condition is not a boolean' do
      context 'when the condition is a number' do
        let(:text) do
          <<~TEXT
            while 69 do
              puts 'I will NEVER eval!'
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to raise_error(RuntimeError, 'Condition for "while" loop must evaluate to a boolean, got: "69"')
        end
      end

      context 'when the condition is a string' do
        let(:text) do
          <<~TEXT
            while "I am text" do
              puts 'I will NEVER eval!'
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to raise_error(RuntimeError, 'Condition for "while" loop must evaluate to a boolean, got: "I am text"')
        end
      end

      context 'when the condition is an array' do
        let(:text) do
          <<~TEXT
            arr = [1]
            while arr do
              puts 'I will NEVER eval!'
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to raise_error(RuntimeError)
        end
      end
    end
  end
end
