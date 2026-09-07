# frozen_string_literal: true

require 'spec_helper'

require_relative 'shared_examples'

RSpec.describe 'Testing from..to loops', type: :feature do
  describe 'using from..to loops' do
    context 'when printing the numbers from 1 to 10' do
      let(:text) do
        <<~TEXT
          from i = 0 to 10 do
            print i
          end
        TEXT
      end

      it_behaves_like 'prints numbers sequentially'
    end

    context 'when summing the numbers from 1 to 10' do
      let(:text) do
        <<~TEXT
          sum = 0
          from i = 0 to 10 do
            sum = sum + i
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

          from i = 0 to length do
            product = product * array[i]
          end

          puts product
        TEXT
      end

      it_behaves_like 'calculates product of an array'
    end

    context 'when lower and upper bounds are inverted' do
      let(:text) do
        <<~TEXT
          from i = 10 to 0 do
            print i
          end
        TEXT
      end

      it 'does not evaluate' do
        expect do
          perform_evaluation!(text)
        end.to output('').to_stdout
      end
    end

    context 'when using "break"' do
      context 'when no tokens after "break"' do
        let(:text) do
          <<~TEXT
            from i = 1 to 101 step 3 do
            	if i < 33 do
            		 puts i
            	else
            		 puts "Breaking!"
            		 break
              end
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to output("1\n4\n7\n10\n13\n16\n19\n22\n25\n28\n31\nBreaking!\n").to_stdout
        end
      end

      context 'when there are tokens after "break"' do
        let(:text) do
          <<~TEXT
            from i = 1 to 101 step 3 do
            	if i < 33 do
            		 puts i
            	else
            		 puts "Breaking!"
            		 break

                 puts "I definitely should NEVER EVAL"
              end
            end
          TEXT
        end

        it 'does not evaluate' do
          expect do
            perform_evaluation!(text)
          end.to output("1\n4\n7\n10\n13\n16\n19\n22\n25\n28\n31\nBreaking!\n").to_stdout
        end
      end
    end
  end

  describe 'when either of the loop bounds are NOT numbers' do
    context 'when lower bound is NOT a number' do
      let(:text) do
        <<~TEXT
          from i = 'some text' to 10 do
            print i
          end
        TEXT
      end

      it 'does not evaluate' do
        expect do
          perform_evaluation!(text)
        end.to raise_error(RuntimeError, 'Lower bound for from..to loop must evaluate to a number. Got "some text" at 1:11.')
      end
    end

    context 'when lower bound is NOT a number' do
      let(:text) do
        <<~TEXT
          from i = 1 to 'some text' do
            print i
          end
        TEXT
      end

      it 'does not evaluate' do
        expect do
          perform_evaluation!(text)
        end.to raise_error(RuntimeError, 'Upper bound for from..to loop must evaluate to a number. Got "some text" at 1:16.')
      end
    end
  end
end
