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
          end

          if staff[:picture]
            responsible_staff.picture.purge
            responsible_staff.picture = staff[:picture]
          end
          responsible_staff.introduction = staff[:introduction]
          responsible_staff.save!

          sale_page
        end
      end

      private

      def responsible_staff
        @responsible_staff ||= user.staffs.find(staff[:id])
      end
    end
  end
end
