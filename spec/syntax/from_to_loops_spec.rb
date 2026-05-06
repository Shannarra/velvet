# frozen_string_literal: true

require 'spec_helper'

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

      it 'prints all the numbers' do
        expect do
          perform_evaluation!(text)
        end.to output('0123456789').to_stdout
      end
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

      it 'sums all the numbers' do
        variables = nil
        expect do
          variables = perform_evaluation!(text).root.variables
        end.to output("45\n").to_stdout

        expect(variables['sum']).to have_attributes(value: 45, kind: Syntax::SyntaxKind::NumberToken)
      end
    end

    context 'when getting the product of an array' do
      let(:array) do
        Array.new(rand(20)) { rand(1..100) }
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

      it 'sums all the numbers' do
        product = array.reduce(:*)
        variables = nil
        expect do
          variables = perform_evaluation!(text).root.variables
        end.to output("#{product}\n").to_stdout

        expect(variables['product']).to have_attributes(value: product, kind: Syntax::SyntaxKind::NumberToken)
      end
    end

    context 'when lower and upper bounds are inverted' do
      let(:text) do
        <<~TEXT
          from i = 10 to 0 do
            print i
          end
        TEXT
      end

      it 'prints all the numbers' do
        expect do
          perform_evaluation!(text)
        end.to output('').to_stdout
      end
    end
  end
end
