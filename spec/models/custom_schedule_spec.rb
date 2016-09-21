require 'rails_helper'

RSpec.describe CustomSchedule, type: :model do
  let(:custom_schedule) { FactoryGirl.create(:custom_schedule,
                                              start_time_date_part: "2016-01-01",
                                              start_time_time_part: "07:00",
                                              end_time_time_part: "17:00") }

  describe "#set_start_time" do
    it "set start time" do
      expect(custom_schedule.tap{|c| c.valid? }.start_time).to eq(Time.zone.local(2016, 1, 1, 7))
    end
  end

  describe "#set_end_time" do
    it "set end time" do
      expect(custom_schedule.tap{|c| c.valid? }.end_time).to eq(Time.zone.local(2016, 1, 1, 17))
    end
  end
end
