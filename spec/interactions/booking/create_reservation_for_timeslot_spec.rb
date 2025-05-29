# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::CreateReservationForTimeslot do
  before do
    # Sunday, one day before booking date
    Timecop.freeze(today)
    business_schedule
  end

  let(:today) { Time.zone.local(2019, 5, 12) }
  let(:subscription) { FactoryBot.create(:subscription, :premium) }
  let(:business_schedule) { FactoryBot.create(:business_schedule, shop: shop) } # 9:00 ~ 17:00
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:user) { subscription.user }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user, shop: shop) }
  let(:booking_option) { FactoryBot.create(:booking_option, :multiple_coperation_menus, user: user, booking_pages: booking_page, shops: shop, staffs: [staff, staff2]) } # required time 60, interval 10 minutes
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:booking_start_at) { Time.zone.parse("2019-05-13 09:00") }
  let(:booking_end_at) { booking_start_at.advance(minutes: booking_option.minutes) }
  let(:staff) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
  let(:staff2) { FactoryBot.create(:staff, :full_time, shop: shop, user: user) }
  let(:social_customer) { FactoryBot.create(:social_customer, user: user) }
  let(:social_user_id) { social_customer.social_user_id }
  let(:args) do
    {
      booking_page_id: booking_page.id,
      booking_option_ids: [booking_option.id],
      staff_ids: [staff.id, staff2.id],
      booking_start_at: booking_start_at,
      social_user_id: social_user_id
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
        expect(user.reload.customer_latest_activity_at).to be_present

        expect(reservation.prepare_time).to eq(booking_start_at.advance(minutes: -booking_option.menus.first.interval))
        expect(reservation.start_time).to eq(booking_start_at)
        expect(reservation.end_time).to eq(booking_end_at)
        expect(reservation.ready_time).to eq(booking_end_at.advance(minutes: booking_option.menus.last.interval))
        expect(reservation).to be_pending

        first_menu_reservation_staff = reservation.reservation_staffs.order_by_menu_position.first
        expect(first_menu_reservation_staff.menu).to eq(booking_option.menus.first)
        expect(first_menu_reservation_staff).to be_pending
        expect(first_menu_reservation_staff.prepare_time).to eq(reservation.prepare_time)
        expect(first_menu_reservation_staff.work_start_at).to eq(reservation.start_time)
        expect(first_menu_reservation_staff.work_end_at).to eq(reservation.start_time.advance(minutes: booking_option.menus.first.minutes))
        expect(first_menu_reservation_staff.ready_time).to eq(first_menu_reservation_staff.work_end_at)
        expect(first_menu_reservation_staff.staff).to eq(staff)

        # coperation menu
        last_menu_reservation_staff1 = reservation.reservation_staffs.order_by_menu_position.second
        expect(last_menu_reservation_staff1).to be_pending
        expect(last_menu_reservation_staff1.menu).to eq(booking_option.menus.last)
        expect(last_menu_reservation_staff1.prepare_time).to eq(first_menu_reservation_staff.work_end_at)
        expect(last_menu_reservation_staff1.work_start_at).to eq(first_menu_reservation_staff.work_end_at)
        expect(last_menu_reservation_staff1.work_end_at).to eq(reservation.end_time)
        expect(last_menu_reservation_staff1.ready_time).to eq(reservation.ready_time)

        expect(reservation.menus).to eq(booking_option.menus)
        expect(reservation.menus.first).to eq(booking_option.menus.first)
        expect(reservation.menus.last).to eq(booking_option.menus.last)

        reservation_customer = reservation.reservation_customers.first
        expect(reservation_customer.customer).to eq(customer)
        expect(reservation_customer.booking_amount).to eq(booking_option.amount)
        expect(reservation_customer.booking_page).to eq(booking_page)
        expect(reservation_customer.booking_options).to include(booking_option)
        expect(reservation_customer.tax_include).to eq(booking_option.tax_include)
        expect(reservation_customer.booking_at).to be_present
        expect(reservation_customer.details.new_customer_info).to eq({})

        expect(reservation_customer.booking_options).to include(booking_option)

        expect(customer.social_customer).to eq(social_customer)
      end

      context "when today is 2019-05-13" do
        # Default booking page limit day is 1, that means you couldn't book today, you have to book one day before the reservation day
        let(:today) { Time.zone.local(2019, 5, 13) }

        it "doesn't allow customers to book" do
          args[:customer_info] = { "id": customer.id }
          args[:present_customer_info] = { "id": customer.id }

          expect(outcome).to be_invalid
        end
      end

      context "when customer booking the same reservation" do
        it "updates the existing reservation customer data" do
          args[:customer_info] = { "id": customer.id }
          args[:present_customer_info] = { "id": customer.id }
          reservation = described_class.run!(args)[:reservation]
          # XXX: Somehow clean the existing reservation customer data
          reservation_customer = reservation.reservation_customers.find_by(customer: customer)
          reservation_customer.update(booking_page_id: nil)

          outcome
          expect(reservation_customer.reload.booking_page_id).to eq(booking_page.id)
          expect(user.reload.customer_latest_activity_at).to be_present
        end
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

      context "when customer doesn't have address yet" do
        it "updates customer address directly" do
          args[:customer_info] = { "id": customer.id, "address_details": { 'zip_code': "1000001", "region": "foo", "city": "bar" } }
          args[:present_customer_info] = { "id": customer.id }
          result = outcome.result

          expect(result[:customer].address_details).to eq({
            "zip_code" => "1000001",
            "region" => "foo",
            "city" => "bar",
            "street1" => nil,
            "street2" => nil
          })
        end
      end
    end

    context "when customer_info doesn't exist" do
      context "when some new customer data miss(customer_last_name, customer_first_name etc...)" do
        it "is invalid" do
          expect(outcome).to be_invalid
          expect(outcome.errors.details[:customer_info]).to include(error: :not_enough_customer_data)
        end
      end

      context "when social_customer with customer" do
        let(:existing_customer) { FactoryBot.create(:customer, user: user) }

        context 'when this social_customer is not owner' do
          let(:social_customer) { FactoryBot.create(:social_customer, customer: existing_customer, user: user) }

          it "updates social_customer's customer's info" do
            customer_info_hash = {
              customer_last_name: "foo",
              customer_first_name: "bar",
              customer_phonetic_last_name: "baz",
              customer_phonetic_first_name: "qux",
              customer_phone_number: "123456789",
              customer_email: "example@email.com"
            }
            args.merge!(customer_info_hash)

            expect {
              outcome
            }.not_to change {
              user.customers.count
            }

            result = outcome.result
            customer = result[:customer]
            reservation = result[:reservation]

            expect(customer.id).to eq(existing_customer.id)
            expect(customer.last_name).to eq("foo")
            expect(customer.first_name).to eq("bar")
            expect(customer.phonetic_last_name).to eq("baz")
            expect(customer.phonetic_first_name).to eq("qux")

            reservation_customer = reservation.reservation_customers.first
            expect(reservation_customer.details.new_customer_info).to eq(Hashie::Mash.new({
              last_name: "foo",
              first_name: "bar",
              phonetic_last_name: "baz",
              phonetic_first_name: "qux",
              phone_number: "123456789",
              email: "example@email.com"
            }))

            expect(customer.social_customer).to eq(social_customer)
          end
        end

        context 'when this social_customer is owner' do
          let(:social_customer) { FactoryBot.create(:social_customer, :is_owner, customer: existing_customer, user: user) }

          it 'creates a new customer' do
            customer_info_hash = {
              customer_last_name: "foo",
              customer_first_name: "bar",
              customer_phonetic_last_name: "baz",
              customer_phonetic_first_name: "qux",
              customer_phone_number: "123456789",
              customer_email: "example@email.com"
            }
            args.merge!(customer_info_hash)

            expect {
              outcome
            }.to change {
              user.customers.count
            }.by(1)
            result = outcome.result
            customer = result[:customer]
            reservation = result[:reservation]

            customer.reload
            expect(customer.last_name).to eq("foo")
            expect(customer.first_name).to eq("bar")
            expect(customer.phonetic_last_name).to eq("baz")
            expect(customer.phonetic_first_name).to eq("qux")

            reservation_customer = reservation.reservation_customers.first
            expect(reservation_customer.details.new_customer_info).to eq(Hashie::Mash.new({
              last_name: "foo",
              first_name: "bar",
              phonetic_last_name: "baz",
              phonetic_first_name: "qux",
              phone_number: "123456789",
              email: "example@email.com"
            }))

            expect(customer.social_customer).to be_nil
          end

          context 'when owner indeed try to booking for themselves' do
            context 'when there is match customer' do
              let(:existing_customer) { FactoryBot.create(:customer, user: user, last_name: "foo", first_name: "bar", phone_numbers_details: [{"type" => "mobile", "value" => "123456789"}], emails_details: [{"type" => "mobile", "value" => "example@email.com"}]) }
              let(:social_customer) { FactoryBot.create(:social_customer, :is_owner, customer: existing_customer, user: user) }

              it "does not create new customer" do
                customer_info_hash = {
                  customer_last_name: existing_customer.last_name,
                  customer_first_name: existing_customer.first_name,
                  customer_phone_number: "12345",
                  customer_phonetic_last_name: existing_customer.phonetic_last_name,
                  customer_phonetic_first_name: existing_customer.phonetic_first_name,
                  customer_email: nil
                }
                args.merge!(customer_info_hash)

                expect {
                  outcome
                }.not_to change {
                  user.customers.count
                }
                expect(outcome).to be_valid
                existing_customer.reload
                expect(existing_customer.last_name).to eq("foo")
                expect(existing_customer.first_name).to eq("bar")
                expect(existing_customer.phone_numbers_details).to eq([{"type" => "mobile", "value" => "12345"}])
                expect(existing_customer.emails_details).to eq([{"type" => "mobile", "value" => "example@email.com"}])
              end
            end

            context 'when there is present customer info' do
              let(:social_customer) { FactoryBot.create(:social_customer, :is_owner, customer: customer, user: user) }

              it "does not create new customer" do
                args[:customer_info] = { "id": customer.id }
                args[:present_customer_info] = { "id": customer.id }

                expect {
                  outcome
                }.not_to change {
                  user.customers.count
                }
                expect(outcome).to be_valid
              end
            end
          end
        end
      end

      context "when social_customer without customer(a new customer)" do
        let(:social_customer) { FactoryBot.create(:social_customer, customer: nil, user: user) }

        it "records all the data" do
          customer_info_hash = {
            customer_last_name: "foo",
            customer_first_name: "bar",
            customer_phonetic_last_name: "baz",
            customer_phonetic_first_name: "qux",
            customer_phone_number: "123456789",
            customer_email: "example@email.com"
          }
          args.merge!(customer_info_hash)

          expect {
            outcome
          }.to change {
            user.customers.count
          }.by(1)
          result = outcome.result
          customer = result[:customer]
          reservation = result[:reservation]

          customer.reload
          expect(customer.last_name).to eq("foo")
          expect(customer.first_name).to eq("bar")
          expect(customer.phonetic_last_name).to eq("baz")
          expect(customer.phonetic_first_name).to eq("qux")

          reservation_customer = reservation.reservation_customers.first
          expect(reservation_customer.details.new_customer_info).to eq(Hashie::Mash.new({
            last_name: "foo",
            first_name: "bar",
            phonetic_last_name: "baz",
            phonetic_first_name: "qux",
            phone_number: "123456789",
            email: "example@email.com"
          }))

          expect(customer.social_customer).to eq(social_customer)
        end
      end

      context "when customer without social_customer(a new customer)" do
        let(:social_user_id) { nil }

        it "records all the data" do
          customer_info_hash = {
            customer_last_name: "foo",
            customer_first_name: "bar",
            customer_phonetic_last_name: "baz",
            customer_phonetic_first_name: "qux",
            customer_phone_number: "123456789",
            customer_email: "example@email.com"
          }
          args.merge!(customer_info_hash)

          expect {
            outcome
          }.to change {
            user.customers.count
          }.by(1)
          result = outcome.result
          customer = result[:customer]
          reservation = result[:reservation]

          expect(customer.last_name).to eq("foo")
          expect(customer.first_name).to eq("bar")
          expect(customer.phonetic_last_name).to eq("baz")
          expect(customer.phonetic_first_name).to eq("qux")

          reservation_customer = reservation.reservation_customers.first
          expect(reservation_customer.details.new_customer_info).to eq(Hashie::Mash.new({
            last_name: "foo",
            first_name: "bar",
            phonetic_last_name: "baz",
            phonetic_first_name: "qux",
            phone_number: "123456789",
            email: "example@email.com"
          }))

          expect(customer.social_customer).to be_nil
        end

        context "when there is a customer with same name and phone_number" do
          it "updates existing customer info" do
            existing_customer = FactoryBot.create(
              :customer, user: user,
              last_name: "foo",
              first_name: "bar",
              phone_numbers_details: [{"type" => "mobile", "value" => "123456789"}]
            )
            customer_info_hash = {
              customer_last_name: "foo",
              customer_first_name: "bar",
              customer_phonetic_last_name: "baz",
              customer_phonetic_first_name: "qux",
              customer_phone_number: "123456789",
              customer_email: "example@email.com"
            }
            args.merge!(customer_info_hash)

            expect {
              outcome
            }.not_to change {
              user.customers.count
            }
            result = outcome.result
            existing_customer = result[:customer]
            reservation = result[:reservation]

            expect(existing_customer.last_name).to eq("foo")
            expect(existing_customer.first_name).to eq("bar")
            expect(existing_customer.phonetic_last_name).to eq("baz")
            expect(existing_customer.phonetic_first_name).to eq("qux")

            reservation_customer = reservation.reservation_customers.first
            expect(reservation_customer.details.new_customer_info).to eq(Hashie::Mash.new({
              last_name: "foo",
              first_name: "bar",
              phonetic_last_name: "baz",
              phonetic_first_name: "qux",
              phone_number: "123456789",
              email: "example@email.com"
            }))

            expect(existing_customer.social_customer).to be_nil
          end
        end
      end
    end

    context "when there is same time and menus reservation(menus had the same required time)" do
      let(:booking_option) { FactoryBot.create(:booking_option, :multiple_menus, :restrict_order, user: user, booking_pages: booking_page, shops: shop, staffs: staff) } # required time 60, interval 10 minutes

      it "adds the customer into the existing reservation" do
        args[:customer_info] = { "id": customer.id }
        args[:present_customer_info] = { "id": customer.id }

        present_reservation = FactoryBot.create(:reservation, :reserved, menus: booking_option.menus, shop: shop, start_time: booking_start_at)
        FactoryBot.create(:reservation_customer, :accepted, reservation: present_reservation, customer: FactoryBot.create(:customer, user: user))
        FactoryBot.create(:reservation_customer, :canceled, reservation: present_reservation, customer: FactoryBot.create(:customer, user: user))
        FactoryBot.create(:reservation_customer, :pending, reservation: present_reservation, customer: FactoryBot.create(:customer, user: user))

        expect {
          outcome
        }.to change {
          present_reservation.reload.customers.count
        }.by(1).and not_change {
          present_reservation.aasm_state
        }

        result = outcome.result
        customer = result[:customer]
        reservation = result[:reservation]

        expect(user.reload.customer_latest_activity_at).to be_present
        expect(reservation).to eq(present_reservation)
        expect(reservation.customers).to include(customer)
        expect(reservation.count_of_customers).to eq(reservation.customers.count)
        expect(reservation.count_of_customers).to eq(reservation.reservation_customers.active.count)

        reservation_customer = reservation.reservation_customers.last
        expect(reservation_customer.customer).to eq(customer)
        expect(reservation_customer.booking_amount).to eq(booking_option.amount)
        expect(reservation_customer.booking_page).to eq(booking_page)
        expect(reservation_customer.booking_options).to include(booking_option)
        expect(reservation_customer.tax_include).to eq(booking_option.tax_include)
        expect(reservation_customer.booking_at).to be_present
        expect(reservation_customer.details.new_customer_info).to eq({})
      end

      context "booking option doesn't restrict menus order" do
        let(:booking_option) do
          # required time 60, interval 10 minutes
          FactoryBot.create(:booking_option, :multiple_menus, user: user, booking_pages: booking_page, shops: shop, staffs: staff)
        end

        context "when booking options does NOT have the same menus order but the same required time with the reservation" do
          it "adds the customer into the existing reservation" do
            args[:customer_info] = { "id": customer.id }
            args[:present_customer_info] = { "id": customer.id }

            reverse_menus = booking_option.menus.reverse
            present_reservation = FactoryBot.create(:reservation, :reserved, menus: reverse_menus, shop: shop, start_time: booking_start_at)

            expect {
              outcome
            }.to change {
              present_reservation.reload.customers.count
            }.and not_change {
              present_reservation.aasm_state
            }

            result = outcome.result
            customer = result[:customer]
            reservation = result[:reservation]

            expect(customer).to eq(customer)
            expect(reservation).to eq(present_reservation)
          end

          context "when there is NOT enough space for this new customer" do
            it "books failed" do
              args[:customer_info] = { "id": customer.id }
              args[:present_customer_info] = { "id": customer.id }

              reverse_menus = booking_option.menus.reverse
              present_reservation = FactoryBot.create(:reservation, :reserved, menus: reverse_menus, shop: shop, start_time: booking_start_at,
                                                      customers: [FactoryBot.create(:customer, user: user), FactoryBot.create(:customer, user: user)])

              expect {
                outcome
              }.to not_change {
                present_reservation.reload.customers.count
              }.and not_change {
                present_reservation.aasm_state
              }.and not_change {
                user.customers.count
              }

              expect(outcome).to be_invalid
            end
          end
        end
      end
    end

    # Customer pay online on booking page
    context "when stripe_token exists" do
      before do
        StripeMock.start
        FactoryBot.create(:access_provider, :stripe, user: user)

        # Mock successful PaymentIntent creation for reservation payments
        successful_payment_intent = double(
          id: "pi_test_123",
          status: "succeeded",
          client_secret: "pi_test_123_secret_test",
          as_json: {
            "id" => "pi_test_123",
            "status" => "succeeded",
            "amount" => booking_option.amount.fractional,
            "currency" => booking_option.amount.currency.iso_code
          }
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_payment_intent)

        # Mock payment method retrieval for StripePayReservation
        allow_any_instance_of(CustomerPayments::StripePayReservation).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end
      after { StripeMock.stop }

      let(:stripe_token) { StripeMock.create_test_helper.generate_card_token }

      it "charges customer" do
        args[:customer_info] = { "id": customer.id }
        args[:present_customer_info] = { "id": customer.id }
        args[:stripe_token] = stripe_token

        expect {
          outcome
        }.to change {
          customer.customer_payments.count
        }.by(1)

        result = outcome.result
        reservation_customer = ReservationCustomer.find_by!(reservation: result[:reservation], customer: result[:customer])
        expect(reservation_customer).to be_payment_paid
      end

      context "when something wrong on stripe" do
        it "doesn't charge customer when there's a Stripe card error" do
          args[:customer_info] = { "id": customer.id }
          args[:present_customer_info] = { "id": customer.id }
          args[:stripe_token] = stripe_token

          # Mock failed PaymentIntent
          failed_payment_intent = double(
            id: "pi_failed_123",
            status: "canceled",
            client_secret: "pi_failed_123_secret_test",
            as_json: {
              "id" => "pi_failed_123",
              "status" => "canceled"
            }
          )
          allow(Stripe::PaymentIntent).to receive(:create).and_return(failed_payment_intent)

          expect {
            outcome
          }.to not_change {
            customer.customer_payments.count
          }

          expect(outcome).to be_invalid
          expect(outcome.errors[:base]).to include(I18n.t("active_interaction.errors.models.booking/create_reservation.attributes.base.paying_reservation_something_wrong"))
        end
      end
    end

    context "when sale_page_id exists" do
      let(:sale_page_id) { 1 }

      it "tracks this reservation with customer's sale page" do
        args[:sale_page_id] = sale_page_id
        args[:customer_info] = { "id": customer.id }
        args[:present_customer_info] = { "id": customer.id }

        outcome

        result = outcome.result
        reservation_customer = ReservationCustomer.find_by!(reservation: result[:reservation], customer: result[:customer])
        expect(reservation_customer.sale_page_id).to eq(sale_page_id)
      end
    end

    context "when today's reservation" do
      let(:today) { Time.zone.local(2019, 5, 13) }
      let(:booking_page) { FactoryBot.create(:booking_page, user: user, shop: shop, booking_limit_hours: 0, booking_limit_day: 0) }

      it "notifies pending reservations summary" do
        args[:customer_info] = { "id": customer.id }
        args[:present_customer_info] = { "id": customer.id }

        expect(Notifiers::Users::PendingReservationsSummary).to receive(:perform_later)
        outcome
      end
    end

    context "when function_access_id exists" do
      let(:function_access) { FactoryBot.create(:function_access) }

      it "tracks this reservation with function access" do
        args[:function_access_id] = function_access.id
        args[:customer_info] = { "id": customer.id }
        args[:present_customer_info] = { "id": customer.id }

        outcome

        result = outcome.result
        reservation_customer = ReservationCustomer.find_by!(reservation: result[:reservation], customer: result[:customer])
        expect(reservation_customer.function_access_id).to eq(function_access.id)
      end
    end
  end
end
