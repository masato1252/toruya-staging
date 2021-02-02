# frozen_string_literal: true

require "rails_helper"
require "line_client"

RSpec.describe Lines::Actions::IncomingReservations do
  let(:social_customer) { FactoryBot.create(:social_customer) }
  let(:customer) { social_customer.customer }
  let(:args) do
    {
      social_customer: social_customer
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is no incoming_reservations" do
      it "sends expected message" do
        expect(LineClient).to receive(:send).with(social_customer, I18n.t("line.bot.messages.incoming_reservations.no_incoming_messages"))

        outcome
      end
    end

    context "when there is incoming_reservations" do
      let!(:reservation) { FactoryBot.create(:reservation, customers: [customer], start_time: Time.current.advance(days: 1)) }

      xit "sends expected message" do
        expect(LineClient).to receive(:flex).with(
          social_customer,
          {
            :altText => I18n.t("line.actions.label.incoming_reservations"),
            :type => "flex",
            :contents=> {
              :type => "carousel",
              :contents => [
                {
                  :header => {
                    :layout =>"vertical",
                    :type =>"box",
                    :contents=> [
                      {
                        :align => "start",
                        :size => "lg",
                        :text => "#{I18n.l(reservation.start_time, format: :short_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}",
                        :type => "text",
                        :weight => "bold"
                      },
                      {
                        :align => "start",
                        :color => "#727272",
                        :text => reservation.menus.map(&:display_name).join(", "),
                        :type => "text",
                        :weight => "regular"
                      }
                    ],
                  },
                  :body => {
                    :layout => "vertical",
                    :type => "box",
                    :contents => [
                      {
                        :text => I18n.t("line.bot.messages.incoming_reservations.desc", shop_phone_number: reservation.shop.phone_number),
                        :type => "text",
                        :wrap => true
                      }
                    ]
                  },
                  :footer => {
                    :contents => [
                      {
                        :action => {:label => I18n.t("line.actions.label.call"), :type => "uri", :uri => "tel:#{reservation.shop.phone_number}"},
                        :type => "button",
                        :style=>"secondary"
                      }
                    ],
                    :layout => "horizontal",
                    :type => "box"
                  },
                  :styles => {
                    :body => {
                      :separator => true
                    }
                  },
                  :direction => "ltr",
                  :type => "bubble"
                }
              ]
            }
          }
        )

        outcome
      end
    end
  end
end
