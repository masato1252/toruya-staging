# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customers::FindOrCreateCustomer, type: :interaction do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:last_name) { 'Smith' }
  let(:first_name) { 'John' }
  let(:phonetic_last_name) { 'スミス' }
  let(:phonetic_first_name) { 'ジョン' }
  let(:phone_number) { '1234567890' }
  let(:email) { 'john.smith@example.com' }

  let(:interaction_params) do
    {
      user: user,
      last_name: last_name,
      first_name: first_name,
      phonetic_last_name: phonetic_last_name,
      phonetic_first_name: phonetic_first_name,
      phone_number: phone_number,
      email: email
    }
  end

  describe '#execute' do
    context 'when no customer exists' do
      before do
        allow_any_instance_of(Customers::Find).to receive(:execute).and_return(found_customer: nil)
      end

      it 'creates a new customer' do
        expect {
          described_class.run!(interaction_params)
        }.to change(Customer, :count).by(1)
      end

      it 'returns the new customer with correct attributes' do
        customer = described_class.run!(interaction_params)

        expect(customer).to be_a(Customer)
        expect(customer.last_name).to eq(last_name)
        expect(customer.first_name).to eq(first_name)
        expect(customer.phonetic_last_name).to eq(phonetic_last_name)
        expect(customer.phonetic_first_name).to eq(phonetic_first_name)
        expect(customer.phone_numbers_details).to eq([{ "type" => "mobile", "value" => phone_number }])
        expect(customer.emails_details).to eq([{ "type" => "mobile", "value" => email }])
        expect(customer.user_id).to eq(user.id)
      end
    end

    context 'when customer exists without social_customer' do
      let!(:existing_customer) { FactoryBot.create(:customer, user: user, last_name: last_name, first_name: first_name) }

      before do
        allow_any_instance_of(Customers::Find).to receive(:execute).and_return(found_customer: existing_customer)
      end

      it 'does not create a new customer' do
        expect {
          described_class.run!(interaction_params.merge(social_customer: nil))
        }.not_to change(Customer, :count)
      end

      it 'updates the existing customer with new information' do
        customer = described_class.run!(interaction_params.merge(social_customer: nil))

        expect(customer.id).to eq(existing_customer.id)
        expect(customer.phone_numbers_details).to eq([{ "type" => "mobile", "value" => phone_number }])
        expect(customer.emails_details).to eq([{ "type" => "mobile", "value" => email }])
      end
    end

    context 'when social_customer exists with a customer' do
      let!(:social_customer_customer) { FactoryBot.create(:customer, user: user, last_name: 'Social', first_name: 'Customer') }
      let!(:social_customer) { FactoryBot.create(:social_customer, user: user, customer: social_customer_customer) }

      context 'and found customer is nil' do
        before do
          allow_any_instance_of(Customers::Find).to receive(:execute).and_return(found_customer: nil)
        end

        it 'uses the customer from social_customer' do
          customer = described_class.run!(interaction_params.merge(social_customer: social_customer))

          expect(customer.id).to eq(social_customer_customer.id)
        end

        it 'updates the social_customer.customer with new information' do
          customer = described_class.run!(interaction_params.merge(social_customer: social_customer))

          expect(customer.phone_numbers_details).to eq([{ "type" => "mobile", "value" => phone_number }])
          expect(customer.emails_details).to eq([{ "type" => "mobile", "value" => email }])
        end
      end

      context 'and found customer is different from social_customer.customer' do
        let!(:found_customer) { FactoryBot.create(:customer, user: user, last_name: last_name, first_name: first_name) }

        before do
          allow_any_instance_of(Customers::Find).to receive(:execute).and_return(found_customer: found_customer)
        end

        it 'updates social_customer to use the found customer' do
          described_class.run!(interaction_params.merge(social_customer: social_customer))

          expect(social_customer.reload.customer_id).to eq(found_customer.id)
        end

        context 'when social_customer.customer has no reservations but has online_service_customer_relations' do
          before do
            allow(social_customer_customer.reservations).to receive(:exists?).and_return(false)
            allow(social_customer_customer.online_service_customer_relations).to receive(:exists?).and_return(true)
          end

          it 'marks the original social_customer.customer as deleted' do
            travel_to Time.current do
              described_class.run!(interaction_params.merge(social_customer: social_customer))

              expect(social_customer_customer.reload.deleted_at).to eq(Time.current)
            end
          end
        end

        context 'when social_customer.customer has reservations' do
          before do
            allow(social_customer_customer.reservations).to receive(:exists?).and_return(true)
          end

          it 'does not mark the original social_customer.customer as deleted' do
            described_class.run!(interaction_params.merge(social_customer: social_customer))

            expect(social_customer_customer.reload.deleted_at).to be_nil
          end
        end
      end

      context 'and found customer is the same as social_customer.customer' do
        before do
          allow_any_instance_of(Customers::Find).to receive(:execute).and_return(found_customer: social_customer_customer)
        end

        it 'returns the customer without changing associations' do
          customer = described_class.run!(interaction_params.merge(social_customer: social_customer))

          expect(customer.id).to eq(social_customer_customer.id)
          expect(social_customer.reload.customer_id).to eq(social_customer_customer.id)
        end
      end
    end

    context 'when customer creation fails' do
      before do
        allow_any_instance_of(Customers::Find).to receive(:execute).and_return(found_customer: nil)
        allow(Customer).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Customer.new))
      end

      it 'adds an error and returns nil' do
        outcome = described_class.run(interaction_params)

        expect(outcome).not_to be_valid
        expect(outcome.errors).to be_present
      end
    end
  end
end