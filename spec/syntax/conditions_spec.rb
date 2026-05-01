# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Testing conditions', type: :feature do
  describe 'using booleans' do
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
end
