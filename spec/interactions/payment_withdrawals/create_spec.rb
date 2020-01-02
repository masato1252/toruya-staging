require "rails_helper"

RSpec.describe PaymentWithdrawals::Create do
  let!(:payment) do
    Timecop.travel(1.month.ago) do
      factory.create_payment
    end
  end
  let(:user) { payment.receiver }

  let(:args) do
    {
      user: user,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a PaymentWithdrawal" do
      expect {
        outcome
      }.to change {
        PaymentWithdrawal.where(receiver: user).count
      }.by(1)

      withdrawal = user.payment_withdrawals.last

      expect(withdrawal.payment_ids).to include(payment.id)
      expect(withdrawal.amount).to eq(user.payments.sum(&:amount))
      expect(withdrawal.details["payment_ids"]).to eq([payment.id])
    end
  end
end
