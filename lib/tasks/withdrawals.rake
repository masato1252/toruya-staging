namespace :withdrawals do
  task :create => :environment do
    today = Subscription.today

    if today.day == 1
      Subscription.where(plan: Plan.business_level.take).includes(:user).find_each do |subscription|
        PaymentWithdrawals::Create.run(user: subscription.user)
      end
    end
  end
end

