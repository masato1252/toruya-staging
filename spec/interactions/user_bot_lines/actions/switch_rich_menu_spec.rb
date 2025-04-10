# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserBotLines::Actions::SwitchRichMenu do
  let(:social_account) { FactoryBot.create(:social_account) }
  let(:user) { social_account.user }
  let(:social_user) { FactoryBot.create(:social_user, user: user) }
  let!(:staff_account) { FactoryBot.create(:staff_account, user: user, owner: user) }
  let(:args) do
    {
      social_user: social_user,
      rich_menu_key: rich_menu_key
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when social user doesn't set up social account(line official account) yet" do
      let(:rich_menu_key) { UserBotLines::RichMenus::Dashboard::KEY }
      let(:social_user) { FactoryBot.create(:social_user) }

      it "switch to expected rich_menu" do
        expect(RichMenus::Connect).to receive(:run).with(
          {
            social_target: social_user,
            social_rich_menu: SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY)
          }
        ).and_return(double(invalid?: false, result: double))

        outcome
      end
    end

    context "when try to switch dashboard rich menu" do
      let(:rich_menu_key) { UserBotLines::RichMenus::Dashboard::KEY }

      context "when there is unread message" do
        before { FactoryBot.create(:social_message, social_account: social_account) }

        context "when user is basic plan user" do
          before { user.subscription.update(plan: Plan.basic_level.take) }

          it "switch to notifications dashboard menu" do
            expect(RichMenus::Connect).to receive(:run).with(
              {
                social_target: social_user,
                social_rich_menu: SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::DashboardWithNotifications::KEY)
              }
            ).and_return(double(invalid?: false, result: double))

            outcome
          end
        end

        context "when user is premium plan user" do
          before { user.subscription.update(plan: Plan.premium_level.take, expired_date: Subscription.today.advance(days: 1)) }

          it "switch to notifications dashboard menu" do
            expect(RichMenus::Connect).to receive(:run).with(
              {
                social_target: social_user,
                social_rich_menu: SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::DashboardWithNotifications::KEY)
              }
            ).and_return(double(invalid?: false, result: double))

            outcome
          end
        end
      end

      context "when there is pending reservation" do
        before {
          allow_any_instance_of(User).to receive(:pending_reservations).and_return(double(exists?: true))
        }

        it "switch to notifications dashboard menu" do
          expect(RichMenus::Connect).to receive(:run).with(
            {
              social_target: social_user,
              social_rich_menu: SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::DashboardWithNotifications::KEY)
            }
          ).and_return(double(invalid?: false, result: double))

          outcome
        end
      end

      context "when there is no unread message or pending tasks" do
        it "switch to basic dashboard menu" do
          expect(RichMenus::Connect).to receive(:run).with(
            {
              social_target: social_user,
              social_rich_menu: SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY)
            }
          ).and_return(double(invalid?: false, result: double))

          outcome
        end
      end

      context "when user already stay in the same rich menu" do
        let(:social_user) { FactoryBot.create(:social_user, user: social_account.user, social_rich_menu_key: rich_menu_key) }

        it "doesn't switch rich_menu" do
          expect(RichMenus::Connect).not_to receive(:run)

          outcome
        end
      end
    end
  end
end
