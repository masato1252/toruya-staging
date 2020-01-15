require "rails_helper"

RSpec.describe PaymentWithdrawals::Create do
  before do
    # It is sunday
    Timecop.freeze(transfer_date)
  end
  after { Timecop.return }
  let!(:payment) do
    Timecop.travel(2.month.ago) do
      factory.create_payment
    end
  end
  let(:user) { payment.receiver }
  let(:mailer_spy) { spy(monthly_report: mailer_deliver)  }
  let(:mailer_deliver) { spy(deliver_later: nil)  }
  let(:transfer_date) { Date.new(2019, 11, described_class::TRANSFER_DAY) } # Sunday

  let(:args) do
    {
      user: user,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a PaymentWithdrawal" do
      allow(WithdrawalMailer).to receive(:with).and_return(mailer_spy)

      expect {
        outcome
      }.to change {
        PaymentWithdrawal.where(receiver: user).count
      }.by(1)

      withdrawal = user.payment_withdrawals.last

      expect(withdrawal.payment_ids).to include(payment.id)
      expect(withdrawal.amount).to eq(user.payments.sum(&:amount))
      expect(withdrawal.details["payment_ids"]).to eq([payment.id])
      expect(withdrawal.details["transfer_date"]).to eq(I18n.l(Date.new(2019, 11, 8)))
      expect(WithdrawalMailer).to have_received(:with).with(withdrawal: withdrawal)
    end

    context "when today is monday (regular business day)" do
      let(:transfer_date) { Date.new(2019, 10, described_class::TRANSFER_DAY) } # Thursday

      it "had a correct transfer date" do
        outcome
        withdrawal = user.payment_withdrawals.last

        expect(withdrawal.details["transfer_date"]).to eq(I18n.l(transfer_date))
      end
    end
  end
end
