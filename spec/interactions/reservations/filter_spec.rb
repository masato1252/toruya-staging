require "rails_helper"

RSpec.describe Reservations::Filter do
  let(:user) { FactoryBot.create(:user) }

  describe "#execute" do
    context "when start_date exists" do
      context "when query_type is on" do
        let(:matched_reservation) { FactoryBot.create(:reservation, start_time: Time.now) }
        let(:unmatch_reservation) { FactoryBot.create(:reservation, start_time: Time.now.beginning_of_day.advance(seconds: -1)) }

        it "returns expected reservations" do
          result = described_class.run!(super_user: user, reservation: { query_type: "on", start_date: Time.now.beginning_of_day })

          expect(result).to include(matched_reservation)
          expect(result).not_to include(unmatch_reservation)
        end
      end

      context "when query_type is before" do
        let(:matched_reservation) { FactoryBot.create(:reservation, start_time: Time.now.beginning_of_day.advance(seconds: -1)) }
        let(:unmatch_reservation) { FactoryBot.create(:reservation, start_time: Time.now) }

        it "returns expected reservations" do
          result = described_class.run!(super_user: user, reservation: { query_type: "before", start_date: Time.now.beginning_of_day })

          expect(result).to include(matched_reservation)
          expect(result).not_to include(unmatch_reservation)
        end
      end

      context "when query_type is after" do
        let(:matched_reservation) { FactoryBot.create(:reservation, start_time: Time.now.tomorrow) }
        let(:unmatch_reservation) { FactoryBot.create(:reservation, start_time: Time.now.beginning_of_day.advance(seconds: -1)) }

        it "returns expected reservations" do
          result = described_class.run!(super_user: user, reservation: { query_type: "after", start_date: Time.now.beginning_of_day })

          expect(result).to include(matched_reservation)
          expect(result).not_to include(unmatch_reservation)
        end
      end

      context "when query_type is between" do
        let(:matched_reservation) { FactoryBot.create(:reservation, start_time: Time.now.beginning_of_day) }
        let(:unmatch_reservation) { FactoryBot.create(:reservation, start_time: Time.now.beginning_of_day.advance(seconds: -1)) }

        it "returns expected reservations" do
          result = described_class.run!(super_user: user, reservation: {
            query_type: "between", start_date: Time.now.beginning_of_day, end_date: Time.now.end_of_day
          })

          expect(result).to include(matched_reservation)
          expect(result).not_to include(unmatch_reservation)
        end
      end

      context "when other conditions exist" do
        let(:reservation_conditions) { { query_type: "after", start_date: 1.days.ago } }

        context "when menu_ids exists" do
          let(:matched_menu) { FactoryBot.create(:menu, user: user) }
          let(:unmatched_menu) { FactoryBot.create(:menu, user: user) }

          let(:matched_reservation) { FactoryBot.create(:reservation, menu: matched_menu) }
          let(:unmatch_reservation) { FactoryBot.create(:reservation, menu: unmatched_menu) }

          it "returns expected reservations" do
            result = described_class.run!(super_user: user, reservation: reservation_conditions.merge(menu_ids: [matched_menu.id]))

            expect(result).to include(matched_reservation)
            expect(result).not_to include(unmatch_reservation)
          end
        end

        context "when staff_ids exists" do
          let(:matched_staff) { FactoryBot.create(:staff, user: user) }
          let(:unmatched_staff) { FactoryBot.create(:staff, user: user) }

          let(:matched_reservation) { FactoryBot.create(:reservation, staffs: [matched_staff]) }
          let(:unmatch_reservation) { FactoryBot.create(:reservation, staffs: [unmatched_staff]) }

          it "returns expected reservations" do
            result = described_class.run!(super_user: user, reservation: reservation_conditions.merge(staff_ids: [matched_staff.id]))

            expect(result).to include(matched_reservation)
            expect(result).not_to include(unmatch_reservation)
          end
        end

        context "when has_error exists" do
          let(:matched_reservation) { FactoryBot.create(:reservation, with_warnings: true) }
          let(:unmatch_reservation) { FactoryBot.create(:reservation, with_warnings: false) }

          it "returns expected reservations" do
            result = described_class.run!(super_user: user, reservation: reservation_conditions.merge(with_warnings: true))

            expect(result).to include(matched_reservation)
            expect(result).not_to include(unmatch_reservation)
          end
        end

        context "when states exists" do
          let(:matched_reservation) { FactoryBot.create(:reservation, :reserved) }
          let(:unmatch_reservation) { FactoryBot.create(:reservation, :pending) }

          it "returns expected reservations" do
            result = described_class.run!(super_user: user, reservation: reservation_conditions.merge(states: ["reserved"]))

            expect(result).to include(matched_reservation)
            expect(result).not_to include(unmatch_reservation)
          end
        end
      end
    end
  end
end
