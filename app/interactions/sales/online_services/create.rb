# frozen_string_literal: true

module Sales
  module OnlineServices
    class Create < ActiveInteraction::Base
      object :user
      integer :selected_online_service_id
      integer :selected_template_id
      hash :template_variables, strip: false
      string :introduction_video_url
      integer :normal_price, default: nil
      integer :selling_price, default: nil
      integer :monthly_price, default: nil
      integer :yearly_price, default: nil
      array :selling_multiple_times_price, default: nil do
        integer
      end
      integer :quantity, default: nil
      string :selling_end_at, default: nil
      hash :content do
        file :picture
        string :desc1
        string :desc2
      end
      hash :staff do
        integer :id
        file :picture, default: nil
        string :introduction
      end

      def execute
        ApplicationRecord.transaction do
          picture = content.delete(:picture)

          sale_page = user.sale_pages.create(
            product_id: selected_online_service_id,
            product_type: "OnlineService",
            sale_template_id: selected_template_id,
            sale_template_variables: template_variables,
            introduction_video_url: introduction_video_url,
            normal_price_amount_cents: normal_price,
            selling_price_amount_cents: selling_price,
            selling_multiple_times_price: selling_multiple_times_price,
            quantity: quantity,
            selling_end_at: selling_end_at ? Time.zone.parse(selling_end_at).end_of_day : nil,
            picture: picture,
            content: content,
            staff: responsible_staff,
            slug: SecureRandom.alphanumeric(10)
          )

          sale_page.product.company.update!(template_variables: template_variables)

          if sale_page.errors.present?
            errors.merge!(sale_page.errors)
            return
          end

          if staff[:picture]
            responsible_staff.picture.purge
            responsible_staff.picture = staff[:picture]
          end
          responsible_staff.introduction = staff[:introduction]
          responsible_staff.save!

          # Because some online_service like bundler only know is recurring charge until sale page creation
          if online_service.stripe_product_id.blank? && (monthly_price || yearly_price)
            stripe_product = compose(::OnlineServices::CreateStripeProduct, online_service: online_service)
            online_service.update!(stripe_product_id: stripe_product.id)
          end

          if recurring_prices.present?
            sale_page.update(recurring_prices: recurring_prices)
          end

          sale_page
        end
      end

      private

      def responsible_staff
        @responsible_staff ||= user.staffs.find(staff[:id])
      end

      def online_service
        @online_service ||= OnlineService.find(selected_online_service_id)
      end

      def recurring_prices
        return @prices if defined?(@prices)

        @prices = []

        if monthly_price
          monthly_recurring_price = RecurringPrice.new(
            interval: 'month',
            amount: monthly_price,
            stripe_price_id: compose(
              Sales::OnlineServices::CreateStripePrice,
              online_service: online_service,
              interval: 'month',
              amount: monthly_price
            ).id,
            active: true
          )

          if monthly_recurring_price.valid?
            @prices << monthly_recurring_price.attributes
          else
            errors.add(:monthly_price, :invalid)
            Rollback.error(
              "Invalid Monthly Price",
              backtrace: caller,
              attributes: monthly_recurring_price.attributes,
              message: monthly_recurring_price.errors.full_messages.join
            )
            raise ActiveRecord::Rollback
          end
        end

        if yearly_price
          yearly_recurring_price = RecurringPrice.new(
            interval: 'year',
            amount: yearly_price,
            stripe_price_id: compose(
              Sales::OnlineServices::CreateStripePrice,
              online_service: online_service,
              interval: 'year',
              amount: yearly_price
            ).id,
            active: true
          )

          if yearly_recurring_price.valid?
            @prices << yearly_recurring_price.attributes
          else
            errors.add(:yearly_price, :invalid)
            Rollback.error(
              "Invalid Year Price",
              backtrace: caller,
              attributes: yearly_recurring_price.attributes,
              message: yearly_recurring_price.errors.full_messages.join
            )
            raise ActiveRecord::Rollback
          end
        end

        @prices
      end
    end
  end
end
