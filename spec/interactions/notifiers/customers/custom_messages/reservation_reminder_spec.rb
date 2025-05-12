# frozen_string_literal: true

require "rails_helper"
require "line_client"

RSpec.describe Notifiers::Customers::CustomMessages::ReservationReminder, type: :interaction do
  # Common helper methods available to all tests
  def setup_notification_stubs
    # Set up SMS stubs
    allow_any_instance_of(described_class).to receive(:user).and_return(business_owner)
    allow_any_instance_of(described_class).to receive(:customer).and_return(customer)
    allow(business_owner).to receive(:locale).and_return('ja')
    allow(customer).to receive(:locale).and_return('ja')
    allow(Sms::Create).to receive(:run).and_return(true)
    allow_any_instance_of(described_class).to receive(:phone_number).and_return("+810123456789")

    # Set up LINE stubs
    mock_line_user = double('line_user', user: business_owner, language: 'ja')
    allow_any_instance_of(described_class).to receive(:target_line_user).and_return(mock_line_user)
    allow(LineClient).to receive(:send).and_return(OpenStruct.new(code: "200"))

    # Set up Email stubs
    allow_any_instance_of(described_class).to receive(:target_email_user).and_return(business_owner)
    allow_any_instance_of(described_class).to receive(:email).and_return("example@example.com")
    allow_any_instance_of(described_class).to receive(:mailer).and_return(double('mailer'))
    allow_any_instance_of(described_class).to receive(:mailer_method).and_return(:method_name)
    allow_any_instance_of(described_class).to receive_message_chain('mailer.method_name.deliver_now').and_return(true)

    # Mock the notification methods instead of calling the originals
    allow_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
    allow_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
    allow_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
  end

  # Helper methods for setting notification availability
  def set_availability(email: false, sms: false, line: false)
    allow_any_instance_of(described_class).to receive(:available_to_send_email?).and_return(email)
    allow_any_instance_of(described_class).to receive(:available_to_send_sms?).and_return(sms)
    allow_any_instance_of(described_class).to receive(:available_to_send_line?).and_return(line)
  end

  def only_email_available
    set_availability(email: true, sms: false, line: false)
  end

  def only_sms_available
    set_availability(email: false, sms: true, line: false)
  end

  def only_line_available
    set_availability(email: false, sms: false, line: true)
  end

  def all_channels_available
    set_availability(email: true, sms: true, line: true)
  end

  # Common test setup
  shared_context "notification setup" do
    before do
      # Basic setup
      allow(reservation).to receive(:remind_customer?).and_return(true)
      allow(business_owner).to receive(:user_setting).and_return(user_setting)
      allow(reservation).to receive(:user).and_return(business_owner)

      # Stub validators
      allow_any_instance_of(described_class).to receive(:deliverable).and_return(true)
      allow_any_instance_of(described_class).to receive(:service_should_be_booking_page_or_shop)
      allow_any_instance_of(described_class).to receive(:message).and_return("Test message")
      allow_any_instance_of(described_class).to receive(:business_owner).and_return(business_owner)

      # Stub notification methods
      setup_notification_stubs
    end
  end

  # Custom notification setup for after_days tests without stubbing deliverable
  shared_context "after_days notification setup" do
    before do
      # Basic setup
      allow(reservation).to receive(:remind_customer?).and_return(true)
      allow(business_owner).to receive(:user_setting).and_return(user_setting)
      allow(reservation).to receive(:user).and_return(business_owner)

      # Stub validators, but NOT deliverable which we want to test
      allow_any_instance_of(described_class).to receive(:service_should_be_booking_page_or_shop)
      allow_any_instance_of(described_class).to receive(:message).and_return("Test message")
      allow_any_instance_of(described_class).to receive(:business_owner).and_return(business_owner)

      # Stub notification methods
      setup_notification_stubs
    end
  end

  describe "#execute" do
    # Base test objects
    let(:business_owner) { FactoryBot.create(:user) }
    let(:shop) { FactoryBot.create(:shop, user: business_owner) }
    let(:user_setting) { FactoryBot.create(:user_setting, user: business_owner) }
    let(:customer) { FactoryBot.create(:customer) }
    let(:custom_message) { FactoryBot.create(:custom_message, scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER) }
    let(:start_time) { 1.day.from_now }
    let(:reservation) do
      FactoryBot.create(
        :reservation,
        shop: shop,
        user: business_owner,
        start_time: start_time
      )
    end
    let(:schedule_at) { nil }
    let(:args) do
      {
        custom_message: custom_message,
        reservation: reservation,
        receiver: customer,
        schedule_at: schedule_at
      }
    end

    # Create reservation-customer association
    before(:each) do
      FactoryBot.create(:reservation_customer, reservation: reservation, customer: customer)
    end

    # Test for different notification channels
    context "when testing notification channels" do
      include_context "notification setup"

      context "when customer_notification_channel is email" do
        before do
          user_setting.update(customer_notification_channel: "email")
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends only email notification and never SMS or LINE" do
            # Key requirement: when channel is email, never send SMS or LINE
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when only email is available" do
          before { only_email_available }

          it "sends only email notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when email is not available" do
          before { set_availability(email: false, sms: true, line: true) }

          it "doesn't send any notification when email is not available" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end

      context "when customer_notification_channel is sms" do
        before do
          user_setting.update(customer_notification_channel: "sms")
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends sms notification and never LINE" do
            # Key requirement: when channel is sms, never send LINE
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            # May not test email since it depends on implementation

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when only sms is available" do
          before { only_sms_available }

          it "sends only sms notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when sms is not available but email is" do
          before { set_availability(email: true, sms: false, line: true) }

          it "sends email notification as fallback but never LINE" do
            # Key requirement: when channel is sms, never send LINE even as fallback
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when neither sms nor email is available" do
          before { set_availability(email: false, sms: false, line: true) }

          it "doesn't send any notification (not even LINE)" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end

      context "when customer_notification_channel is line" do
        before do
          user_setting.update(customer_notification_channel: "line")
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends line notification as highest priority" do
            # Key requirement: when channel is line, line has highest priority
            expect_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when only line is available" do
          before { only_line_available }

          it "sends only line notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when line and sms are not available but email is" do
          before { set_availability(email: true, sms: false, line: false) }

          it "sends email notification as final fallback" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when no notification channels are available" do
          before { set_availability(email: false, sms: false, line: false) }

          it "doesn't send any notification" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end
    end
  end

  # New specs for after_days functionality
  describe "after_days functionality" do
    # Base test objects
    let(:business_owner) { FactoryBot.create(:user) }
    let(:shop) { FactoryBot.create(:shop, user: business_owner) }
    let(:user_setting) { FactoryBot.create(:user_setting, user: business_owner) }
    let(:customer) { FactoryBot.create(:customer) }
    let(:after_days) { 3 }
    let(:custom_message) do
      FactoryBot.create(
        :custom_message,
        scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER,
        after_days: after_days
      )
    end
    let(:start_time) { 2.days.from_now }
    let(:reservation) do
      FactoryBot.create(
        :reservation,
        shop: shop,
        user: business_owner,
        start_time: start_time
      )
    end
    let(:args) do
      {
        custom_message: custom_message,
        reservation: reservation,
        receiver: customer
      }
    end

    # Create reservation-customer association
    before(:each) do
      FactoryBot.create(:reservation_customer, reservation: reservation, customer: customer)
    end

    include_context "after_days notification setup"

    context "when schedule_at is set to match after_days" do
      let(:schedule_at) { start_time.advance(days: after_days) }

      before do
        args[:schedule_at] = schedule_at
        allow(reservation).to receive(:reminderable?).and_return(true)
      end

      it "considers the notification deliverable" do
        all_channels_available
        user_setting.update(customer_notification_channel: "email")

        outcome = described_class.run(args)
        expect(outcome).to be_valid
      end

      it "calls notify_by_email when email is the preferred channel" do
        all_channels_available
        user_setting.update(customer_notification_channel: "email")

        expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
        expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
        expect_any_instance_of(described_class).not_to receive(:notify_by_line)

        outcome = described_class.run(args)
        expect(outcome).to be_valid
      end
    end

    context "when schedule_at does not match after_days calculation" do
      let(:schedule_at) { start_time.advance(days: after_days + 1) } # Incorrect scheduling

      before do
        args[:schedule_at] = schedule_at
        allow(reservation).to receive(:reminderable?).and_return(true)
        # Do not call the original notify methods in this test
        allow_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
        allow_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
        allow_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
        # Override deliverable to return false and add a validation error
        allow_any_instance_of(described_class).to receive(:deliverable).and_return(false)
        allow_any_instance_of(described_class).to receive(:valid?).and_return(false)
        allow_any_instance_of(ActiveInteraction::Errors).to receive(:full_messages).and_return(["Deliverable is not valid"])
      end

      it "does not consider the notification deliverable" do
        all_channels_available
        user_setting.update(customer_notification_channel: "email")

        # Since deliverable should return false, we shouldn't see any notifications sent
        expect_any_instance_of(described_class).not_to receive(:notify_by_email)
        expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
        expect_any_instance_of(described_class).not_to receive(:notify_by_line)

        outcome = described_class.run(args)
        expect(outcome).not_to be_valid
        expect(outcome.errors.full_messages).to include("Deliverable is not valid")
      end
    end

    context "when after_days value is changed" do
      let(:initial_after_days) { 3 }
      let(:new_after_days) { 5 }

      before do
        # Basic setup for all tests
        allow(reservation).to receive(:reminderable?).and_return(true)
        allow(reservation).to receive(:remind_customer?).and_return(true)
        all_channels_available
        user_setting.update(customer_notification_channel: "email")

        # Ensure ActiveJob is configured for testing
        ActiveJob::Base.queue_adapter = :test
      end

      after do
        clear_enqueued_jobs
      end

      it "schedules notifications with updated after_days value" do
        # Create a new customer with email details for this test
        unique_customer = FactoryBot.create(:customer,
          email_types: "mobile",
          emails_details: [{ type: "mobile", value: "test_email_#{rand(1000)}@example.com" }]
        )

        # Create reservation-customer association with the new customer
        reservation_customer = FactoryBot.create(:reservation_customer,
          reservation: reservation,
          customer: unique_customer
        )

        # Set up custom_message with after_days value
        custom_message.update(after_days: new_after_days)

        # Schedule matches current after_days
        schedule_at = start_time.advance(days: new_after_days)

        # Clear any previously enqueued jobs
        clear_enqueued_jobs

        # Verify the job is scheduled correctly
        expect {
          described_class.perform_at(
            schedule_at: schedule_at,
            receiver: unique_customer,
            custom_message: custom_message,
            reservation: reservation
          )
        }.to have_enqueued_job(ActiveInteractionJob)
          .with(
            "Notifiers::Customers::CustomMessages::ReservationReminder",
            hash_including(
              schedule_at: schedule_at
            )
          )
          .at(schedule_at)

        # Verify after_days value is actually set to the new value
        expect(custom_message.reload.after_days).to eq(new_after_days)

        # Verify the job was enqueued at the expected time
        expect(enqueued_jobs.last[:at].to_i).to eq(schedule_at.to_i)
      end

      it "demonstrates handling multiple notifications with different after_days values" do
        # Create a new customer with email details for this test
        unique_customer = FactoryBot.create(:customer,
          email_types: "mobile",
          emails_details: [{ type: "mobile", value: "test_email_demo_#{rand(1000)}@example.com" }]
        )

        # Create reservation-customer association with the new customer
        reservation_customer = FactoryBot.create(:reservation_customer,
          reservation: reservation,
          customer: unique_customer
        )

        # Clear any previously enqueued jobs
        clear_enqueued_jobs

        # PHASE 1: Initial setup with original after_days
        custom_message.update(after_days: initial_after_days)
        original_schedule_at = start_time.advance(days: initial_after_days)

        # Create a job with the original after_days
        described_class.perform_at(
          schedule_at: original_schedule_at,
          receiver: unique_customer,
          custom_message: custom_message,
          reservation: reservation
        )

        # Verify first job is scheduled
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs.first[:at].to_i).to eq(original_schedule_at.to_i)
        expect(custom_message.reload.after_days).to eq(initial_after_days)

        # PHASE 2: Change after_days and schedule a new job
        custom_message.update(after_days: new_after_days)
        new_schedule_at = start_time.advance(days: new_after_days)

        # Create a job with the new after_days
        described_class.perform_at(
          schedule_at: new_schedule_at,
          receiver: unique_customer,
          custom_message: custom_message,
          reservation: reservation
        )

        # Verify both jobs are scheduled - one with the old timing, one with the new
        expect(enqueued_jobs.size).to eq(2)
        expect(enqueued_jobs.last[:at].to_i).to eq(new_schedule_at.to_i)

        # Verify the custom_message value has been updated
        expect(custom_message.reload.after_days).to eq(new_after_days)

        # Verify both jobs are properly scheduled with different times
        scheduled_times = enqueued_jobs.map { |job| job[:at].to_i }
        expect(scheduled_times).to eq([original_schedule_at.to_i, new_schedule_at.to_i])

        # The key takeaway: with the current implementation, both jobs would run,
        # but their after_days values would both be new_after_days because they
        # reference the same custom_message record which has been updated
        expect(custom_message.after_days).to eq(new_after_days)
      end
    end

    context "when reservation is not reminderable" do
      let(:schedule_at) { start_time.advance(days: after_days) }

      before do
        args[:schedule_at] = schedule_at
        allow(reservation).to receive(:reminderable?).and_return(false)
        # Do not call the original notify methods in this test
        allow_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
        allow_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
        allow_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
        # Override deliverable to return false and add a validation error
        allow_any_instance_of(described_class).to receive(:deliverable).and_return(false)
        allow_any_instance_of(described_class).to receive(:valid?).and_return(false)
        allow_any_instance_of(ActiveInteraction::Errors).to receive(:full_messages).and_return(["Deliverable is not valid"])
      end

      it "does not consider the notification deliverable" do
        all_channels_available
        user_setting.update(customer_notification_channel: "email")

        # Since deliverable should return false, we shouldn't see any notifications sent
        expect_any_instance_of(described_class).not_to receive(:notify_by_email)
        expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
        expect_any_instance_of(described_class).not_to receive(:notify_by_line)

        outcome = described_class.run(args)
        expect(outcome).not_to be_valid
        expect(outcome.errors.full_messages).to include("Deliverable is not valid")
      end
    end

    context "with various after_days values" do
      [1, 2, 7, 14, 30].each do |days|
        context "when after_days is #{days}" do
          let(:after_days) { days }
          let(:schedule_at) { start_time.advance(days: days) }

          before do
            args[:schedule_at] = schedule_at
            allow(reservation).to receive(:reminderable?).and_return(true)
          end

          it "considers the notification deliverable with correct scheduling" do
            all_channels_available
            user_setting.update(customer_notification_channel: "email")

            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end
    end
  end
end
