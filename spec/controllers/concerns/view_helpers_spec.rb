# frozen_string_literal: true

require "rails_helper"

class FakesController < ApplicationController
  include ViewHelpers
end

RSpec.describe FakesController do
  before do
    allow(subject).to receive(:current_user).and_return(current_user)
    allow(subject).to receive(:super_user).and_return(super_user)
  end

  let(:staff) { FactoryBot.create(:staff) }
  let(:current_user) { staff.staff_account.user }
  let(:super_user) { staff.staff_account.owner }
  let(:shop) { staff.shops.take  }

end
