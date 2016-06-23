require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Vadik', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Misha', balance: 3000)
    ])

    render
  end

  it 'renders players names' do
    expect(rendered).to match 'Vadik'
    expect(rendered).to match 'Misha'
  end

  it 'renders players balances' do
    expect(rendered).to match '5 000 '
    expect(rendered).to match '3 000 '
  end

  it 'renders players names in right order' do
    expect(rendered).to match /Vadik.*Misha/m

  end
end