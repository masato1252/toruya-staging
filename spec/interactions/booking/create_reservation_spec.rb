require "rails_helper"

RSpec.describe Booking::CreateReservation do
  before do
    # Monday
    Timecop.freeze(Time.zone.local(2019, 5, 13))
  end

  let(:business_schedule) { FactoryBot.create(:business_schedule) } # 9:00 ~ 17:00
  let(:shop) { business_schedule.shop }
  let(:user) { shop.user }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user, shop: shop) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user, booking_pages: booking_page, shops: shop, staffs: staff) } # required time 60, interval 10 minutes
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:booking_start_at) { Time.zone.parse("2019-05-13 09:00") }
  let(:staff) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
  let(:args) do
    {
      booking_page_id: booking_page.id,
      booking_option_id: booking_option.id,
      booking_start_at: booking_start_at
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when customer_info exists(user is regular customer)" do
      it "returns expected result" do
        args[:customer_info] = { "id": customer.id }
        args[:present_customer_info] = { "id": customer.id }

        result = outcome.result
        customer = result[:customer]
        reservation = result[:reservation]

        expect(customer).to eq(customer)
        expect(reservation.start_time).to eq(booking_start_at)
        expect(reservation.end_time).to eq(booking_start_at.advance(minutes: booking_option.minutes))

        expect(reservation.staffs.first).to eq(staff)

        reservation_customer = reservation.reservation_customers.first

        expect(reservation_customer.customer).to eq(customer)
        expect(reservation_customer.amount).to eq(booking_option.amount)
        expect(reservation_customer.booking_page).to eq(booking_page)
        expect(reservation_customer.booking_option).to eq(booking_option)
        expect(reservation_customer.tax_include).to eq(booking_option.tax_include)
        expect(reservation_customer.booking_at).to be_present
        expect(reservation_customer.details.new_customer_info).to eq({})
      end

      context "when customer changes their data" do
        it "records the data changes" do
          args[:customer_info] = { "id": customer.id, "last_name": "foo" }
          args[:present_customer_info] = { "id": customer.id }

          result = outcome.result
          reservation = result[:reservation]

          reservation_customer = reservation.reservation_customers.first
          expect(reservation_customer.details.new_customer_info).to eq({ "last_name" => "foo" })
        end
      end
    end

    context "when customer_info doesn't exist(a new customer)" do
      context "when some new customer data miss(customer_last_name, customer_first_name etc...)" do
        it "is invalid" do
          expect(outcome).to be_invalid
          expect(outcome.errors.details[:customer_info]).to include(error: :not_enough_customer_data)
        end
      end

      it "records all the data" do
        google_user = spy(create_contact: spy(id: "google_contact_id"))
        allow(GoogleContactsApi::User).to receive(:new).and_return(google_user)

        customer_info_hash = {
          customer_last_name: "foo",
          customer_first_name: "bar",
          customer_phonetic_last_name: "baz",
          customer_phonetic_first_name: "qux",
          customer_phone_number: "123456789",
          customer_email: "example@email.com"
        }
        args.merge!(customer_info_hash)

        result = outcome.result
        customer = result[:customer]
        reservation = result[:reservation]

        expect(customer.last_name).to eq("foo")
        expect(customer.first_name).to eq("bar")
        expect(customer.phonetic_last_name).to eq("baz")
        expect(customer.phonetic_first_name).to eq("qux")
        expect(customer.google_contact_id).to eq("google_contact_id")
        expect(customer.google_uid).to eq(user.uid)

        reservation_customer = reservation.reservation_customers.first
        expect(reservation_customer.details.new_customer_info).to eq(Hashie::Mash.new({
          last_name: "foo",
          first_name: "bar",
          phonetic_last_name: "baz",
          phonetic_first_name: "qux",
          phone_number: "123456789",
          email: "example@email.com"
        }))
      end
    end

    context "when there is same time and menus reservation(menus had same the required time)" do
      context "booking option restrict menus order" do
        let(:booking_option) do
          # required time 60, interval 10 minutes
          FactoryBot.create(:booking_option, :multiple_menus, :restrict_order, user: user, booking_pages: booking_page, shops: shop, staffs: staff)
        end

        context "when booking options had the same menus order and required time with the reservation" do
          it "adds the customer into the existing reservation" do
            present_reservation = FactoryBot.create(:reservation, :reserved, menus: booking_option.menus, shop: shop, start_time: booking_start_at)
            args[:customer_info] = { "id": customer.id }
            args[:present_customer_info] = { "id": customer.id }

            expect {
              outcome
            }.to change {
              present_reservation.reload.customers.count
            }.by(1).and change {
              present_reservation.aasm_state
            }.from("reserved").to("pending")

            result = outcome.result
            customer = result[:customer]
            reservation = result[:reservation]

            expect(reservation).to eq(present_reservation)
            expect(reservation.customers).to include(customer)
          end
        end

        context "when booking options had the same menus order and required time with the reservation" do
          it "doesn't adds the customer into the existing reservation" do
            args[:customer_info] = { "id": customer.id }
            args[:present_customer_info] = { "id": customer.id }
            reverse_menus = booking_option.menus.reverse
            present_reservation = FactoryBot.create(:reservation, :reserved, menus: reverse_menus, shop: shop, start_time: booking_start_at)

            expect {
              outcome
            }.to not_change {
              present_reservation.reload.customers.count
            }.and not_change {
              present_reservation.aasm_state
            }

            result = outcome.result
            customer = result[:customer]
            reservation = result[:reservation]

            expect(customer).to eq(customer)
            expect(reservation).to be_nil
          end
        end
      end

      context "booking option doesn't restrict menus order" do
      end

      context "when there is enough space for this new customer" do
      end

      context "when there is NOT enough space for this new customer" do
      end
    end
  end
end
