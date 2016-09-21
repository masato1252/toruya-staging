require 'rails_helper'

RSpec.describe Customer, type: :model do
  it "" do
    FactoryGirl.create(:customer, last_name: "あ")
  end
end
