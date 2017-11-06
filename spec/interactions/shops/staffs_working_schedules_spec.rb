require "rails_helper"

RSpec.describe Shops::StaffsWorkingSchedules do
  describe "#execute" do
    let(:shop) { FactoryBot.create(:shop) }
    let(:date) { Date.today }

    context "when date is not working day" do
      it "is invalid" do
        expect(described_class.run(shop: shop, date: date)).to be_invalid
      end
    end

    context "when date is a working day" do
      before { FactoryBot.create(:business_schedule, shop: shop, start_time: start_time, end_time: end_time) }
      let!(:staff) { FactoryBot.create(:staff, shop: shop) }
      let(:start_time) { Time.zone.local(date.year, date.month, date.day, 9, 0, 0) }
      let(:end_time) { Time.zone.local(date.year, date.month, date.day, 17, 0, 0) }
      let(:start_time2) { Time.zone.local(date.year, date.month, date.day, 10, 0, 0) }
      let(:end_time2) { Time.zone.local(date.year, date.month, date.day, 16, 0, 0) }

      context "when there is full time staff working on this date" do
        let!(:staff) { FactoryBot.create(:staff, :full_time, shop: shop) }

        it "returns expect result" do
          expect(described_class.run!(shop: shop, date: date)).to eq({
            staff => { time: start_time..end_time }
          })
        end
      end

      context "when there is weekly part time staff working on this date" do
        before { FactoryBot.create(:business_schedule, shop: shop, staff: staff, start_time: start_time2, end_time: end_time2) }

        it "returns expect result" do
          expect(described_class.run!(shop: shop, date: date)).to eq({
            staff => { time: start_time2..end_time2 }
          })
        end
      end

      context "when there is temporary part time staff working on this date" do
        before { FactoryBot.create(:custom_schedule, :opened, shop: shop, staff: staff, start_time: start_time2, end_time: end_time2) }

        it "returns expect result" do
          expect(described_class.run!(shop: shop, date: date)).to eq({
            staff => { time: start_time2..end_time2 }
          })
        end
      end

      context "when there is staff working on this date but need to leave" do
        let!(:staff) { FactoryBot.create(:staff, :full_time, shop: shop) }
        before { FactoryBot.create(:custom_schedule, shop: shop, staff: staff, start_time: start_time2, end_time: end_time2, reason: "foo") }

        context "when leaving after working time start(like working in the morning, leaving in the afternoon)" do
          let(:start_time) { Time.zone.local(date.year, date.month, date.day, 9, 0, 0) }
          let(:start_time2) { Time.zone.local(date.year, date.month, date.day, 11, 0, 0) }

          it "returns expect result" do
            expect(described_class.run!(shop: shop, date: date)).to eq({
              staff => { time: start_time..start_time2, reason: "foo" }
            })
          end
        end

        context "when coming back before working time end(like OOO in the morning, working in the afternoon)" do
          let(:start_time2) { Time.zone.local(date.year, date.month, date.day, 8, 0, 0) }
          let(:end_time2) { Time.zone.local(date.year, date.month, date.day, 11, 0, 0) }

          it "returns expect result" do
            expect(described_class.run!(shop: shop, date: date)).to eq({
              staff => { time: end_time2..end_time, reason: "foo" }
            })
          end
        end

        context "when leaving all day" do
          let(:start_time2) { Time.zone.local(date.year, date.month, date.day, 0, 0, 0) }
          let(:end_time2) { Time.zone.local(date.year, date.month, date.day, 23, 0, 0) }

          it "returns expect result" do
            expect(described_class.run!(shop: shop, date: date)).to eq({
              staff => { time: nil, reason: "foo" }
            })
          end
        end
      end
    end
  end
end
