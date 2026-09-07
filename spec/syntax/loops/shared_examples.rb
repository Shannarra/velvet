# frozen_string_literal: true

require 'spec_helper'

shared_examples 'prints numbers sequentially' do
  it 'prints all the numbers' do
    expect do
      perform_evaluation!(text)
    end.to output('0123456789').to_stdout
  end
end

shared_examples 'sums numbers from 1 to 10' do
  it 'sums all the numbers' do
    variables = nil
    expect do
      variables = perform_evaluation!(text).root.variables
    end.to output("45\n").to_stdout

    expect(variables['sum']).to have_attributes(value: 45, kind: Syntax::SyntaxKind::NumberToken)
  end
end

shared_examples 'calculates product of an array' do
  it 'sums all the numbers' do
    product = array.reduce(:*)
    variables = nil
    expect do
      variables = perform_evaluation!(text).root.variables
    end.to output("#{product}\n").to_stdout

    expect(variables['product']).to have_attributes(value: product, kind: Syntax::SyntaxKind::NumberToken)
  end
end
