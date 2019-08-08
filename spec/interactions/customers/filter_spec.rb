require "rails_helper"

RSpec.describe Customers::Filter do
  let(:user) { staff.user }
  let(:staff) { FactoryBot.create(:staff, :with_contact_groups) }
  let(:readable_contact_group) { staff.readable_contact_groups.first }
  let(:default_customer_options) { { user: user, contact_group: readable_contact_group } }
  let(:group_ids) { [] }
  let(:living_place) { {} }
  let(:args) do
    {
      super_user: user,
      current_user_staff: staff,
      group_ids: group_ids,
      living_place: living_place,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when group_ids option exists" do
      let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user) }
      let(:group_ids) { [matched_customer.contact_group_id.to_s] }

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end

    context "when states option exists" do
      let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(address: "三重県 亀山市")) }
      let!(:matched_customer2) { FactoryBot.create(:customer, default_customer_options.merge(address: "二重県 清須市")) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(address: "四重県 桑名市")) }
      let!(:unmatched_customer2) { FactoryBot.create(:customer, default_customer_options.merge(address: "五重県 桑名市")) }

      let(:living_place) do
        { inside: true, states: ["三重県", "二重県"] }
      end

      context "when inside option is true" do
        it "returns expected customers" do
          result = outcome.result

          expect(result).to include(matched_customer)
          expect(result).to include(matched_customer2)
          expect(result).not_to include(unmatched_customer)
          expect(result).not_to include(unmatched_customer2)
        end
      end

      context "when inside option is false" do
        let(:living_place) do
          { inside: false, states: ["四重県", "五重県"] }
        end

        it "returns expected customers" do
          result = outcome.result

          expect(result).to include(matched_customer)
          expect(result).to include(matched_customer2)
          expect(result).not_to include(unmatched_customer)
          expect(result).not_to include(unmatched_customer2)
        end
      end
    end

    context "when has_email exists" do
      context "When has_email is true" do
        context "when email_types doesn't exists" do
          let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(email_types: "mobile")) }
          let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options) }

          it "returns expected customers" do
            args.merge!(has_email: true)
            result = outcome.result

            expect(result).to include(matched_customer)
            expect(result).not_to include(unmatched_customer)
          end
        end

        context "when email_types exists" do
          let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(email_types: "mobile,work")) }
          let!(:matched_customer2) { FactoryBot.create(:customer, default_customer_options.merge(email_types: "work")) }
          let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(email_types: "home,other")) }

          it "returns expected customers" do
            args.merge!(has_email: true, email_types: ["work", "mobile"])
            result = outcome.result

            expect(result).to include(matched_customer)
            expect(result).to include(matched_customer2)
            expect(result).not_to include(unmatched_customer)
          end
        end
      end

      context "When has_email is false" do
        let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options) }
        let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(email_types: "mobile")) }

        it "returns expected customers" do
          args.merge!(has_email: false)
          result = outcome.result

          expect(result).to include(matched_customer)
          expect(result).not_to include(unmatched_customer)
        end
      end
    end

    context "when birthday conditions is valid" do
      context "when birthday month condition exists" do
        let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current)) }
        let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current.advance(months: 1))) }

        it "returns expected customers" do
          args.merge!(birthday: { query_type: "on_month", month: Date.current.month })
          result = outcome.result

          expect(result).to include(matched_customer)
          expect(result).not_to include(unmatched_customer)
        end
      end

      context "when birthday start_date exists" do
        context "when birthday query_type is on" do
          let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current.yesterday)) }
          let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current)) }

          it "returns expected customers" do
            args.merge!(birthday: { query_type: "on", start_date: Date.current.yesterday })
            result = outcome.result

            expect(result).to include(matched_customer)
            expect(result).not_to include(unmatched_customer)
          end
        end

        context "when birthday query_type is before" do
          let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current.yesterday)) }
          let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current)) }

          it "returns expected customers" do
            args.merge!(birthday: { query_type: "before", start_date: Date.current })
            result = outcome.result

            expect(result).to include(matched_customer)
            expect(result).not_to include(unmatched_customer)
          end
        end

        context "when birthday query_type is after" do
          let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current.tomorrow)) }
          let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current)) }

          it "returns expected customers" do
            args.merge!(birthday: { query_type: "after", start_date: Date.current })
            result = outcome.result

            expect(result).to include(matched_customer)
            expect(result).not_to include(unmatched_customer)
          end
        end

        context "when birthday query_type is between" do
          let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current)) }
          let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(birthday: Date.current.yesterday)) }

          it "returns expected customers" do
            args.merge!(birthday: { query_type: "between", start_date: Date.current, end_date: Date.current.tomorrow })
            result = outcome.result

            expect(result).to include(matched_customer)
            expect(result).not_to include(unmatched_customer)
          end
        end
      end
    end

    context "when custom_id exists" do
      let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(custom_id: "fooo")) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(custom_id: "bar")) }

      it "returns expected customers" do
        args.merge!(custom_ids: ["Foo"])
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end

    context "when reservation conditions exists" do
      let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options) }

      context "when has_reservation is true" do
        let(:reservation_conditions) { { has_reservation: true } }

        context "when start_date exists" do
          context "when query_type is on" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now)
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "on", start_date: Time.now.beginning_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when query_type is before" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now)
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "before", start_date: Time.now.beginning_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when query_type is after" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now.tomorrow)
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "after", start_date: Time.now.beginning_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when query_type is between" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now.beginning_of_day)
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "between", start_date: Time.now.beginning_of_day, end_date: Time.now.end_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when other conditions exist" do
            let(:reservation_conditions) { { has_reservation: true, query_type: "after", start_date: 1.days.ago } }

            context "when shop_ids exists" do
              let(:matched_shop) { FactoryBot.create(:shop, user: user) }
              let(:unmatched_shop) { FactoryBot.create(:shop, user: user) }

              before do
                FactoryBot.create(:reservation, customers: [matched_customer], shop: matched_shop)
                FactoryBot.create(:reservation, customers: [unmatched_customer], shop: unmatched_shop)
              end

              it "returns expected customers" do
                args.merge!(reservation: reservation_conditions.merge(shop_ids: [matched_shop.id]))
                result = outcome.result

                expect(result).to include(matched_customer)
                expect(result).not_to include(unmatched_customer)
              end
            end

            context "when menu_ids exists" do
              let(:matched_menu) { FactoryBot.create(:menu, user: user) }
              let(:unmatched_menu) { FactoryBot.create(:menu, user: user) }

              before do
                FactoryBot.create(:reservation, customers: [matched_customer], menu: matched_menu)
                FactoryBot.create(:reservation, customers: [unmatched_customer], menu: unmatched_menu)
              end

              it "returns expected customers" do
                args.merge!(reservation: reservation_conditions.merge(menu_ids: [matched_menu.id]))
                result = outcome.result

                expect(result).to include(matched_customer)
                expect(result).not_to include(unmatched_customer)
              end
            end

            context "when staff_ids exists" do
              let(:matched_staff) { FactoryBot.create(:staff, user: user) }
              let(:unmatched_staff) { FactoryBot.create(:staff, user: user) }

              before do
                FactoryBot.create(:reservation, customers: [matched_customer], staffs: [matched_staff])
                FactoryBot.create(:reservation, customers: [unmatched_customer], staffs: [unmatched_staff])
              end

              it "returns expected customers" do
                args.merge!(reservation: reservation_conditions.merge(staff_ids: [matched_staff.id]))
                result = outcome.result

                expect(result).to include(matched_customer)
                expect(result).not_to include(unmatched_customer)
              end
            end

            context "when has_error exists" do
              before do
                FactoryBot.create(:reservation, customers: [matched_customer], with_warnings: true)
                FactoryBot.create(:reservation, customers: [unmatched_customer], with_warnings: false)
              end

              it "returns expected customers" do
                args.merge!(reservation: reservation_conditions.merge(with_warnings: true))
                result = outcome.result

                expect(result).to include(matched_customer)
                expect(result).not_to include(unmatched_customer)
              end
            end

            context "when states exists" do
              before do
                FactoryBot.create(:reservation, :reserved, customers: [matched_customer])
                FactoryBot.create(:reservation, :pending, customers: [unmatched_customer])
              end

              it "returns expected customers" do
                args.merge!(reservation: reservation_conditions.merge(states: ["reserved"]))
                result = outcome.result

                expect(result).to include(matched_customer)
                expect(result).not_to include(unmatched_customer)
              end
            end
          end
        end
      end

      context "when has_reservation is false" do
        let(:reservation_conditions) { { has_reservation: false } }

        context "when start_date exists" do
          context "when query_type is on" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now)
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "on", start_date: Time.now.beginning_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when query_type is before" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now)
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now)
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "before", start_date: Time.now.beginning_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when query_type is after" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.tomorrow)
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "after", start_date: Time.now.beginning_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end

          context "when query_type is between" do
            before do
              FactoryBot.create(:reservation, customers: [matched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day)
              FactoryBot.create(:reservation, customers: [unmatched_customer], start_time: Time.now.beginning_of_day.advance(seconds: -1))
            end

            it "returns expected customers" do
              args.merge!(reservation: reservation_conditions.merge(query_type: "between", start_date: Time.now.beginning_of_day, end_date: Time.now.end_of_day))
              result = outcome.result

              expect(result).to include(matched_customer)
              expect(result).not_to include(unmatched_customer)
            end
          end
        end
      end
    end
  end
end
