# frozen_string_literal: true

module Sales
  module BookingPages
    class Create < ActiveInteraction::Base
      object :user
      integer :id, default: nil
      boolean :draft, default: false
      integer :selected_booking_page
      integer :selected_template, default: nil
      hash :template_variables, strip: false
      hash :product_content, default: nil do
        file :picture, default: nil
        string :desc1, default: nil
        string :desc2, default: nil
      end
      hash :staff, default: nil do
        integer :id, default: nil
        file :picture, default: nil
        string :introduction, default: nil
      end
      array :flow, default: nil do
        string
      end

      def execute
        ApplicationRecord.transaction do
          picture = product_content.delete(:picture)

          sale_page = id ? user.sale_pages.find(id) : user.sale_pages.build

          sale_page.picture = picture if picture
          sale_page.assign_attributes(
            product_id: selected_booking_page,
            product_type: "BookingPage",
            sale_template_id: selected_template,
            sale_template_variables: template_variables,
            content: product_content,
            flow: flow,
            staff: responsible_staff,
            slug: SecureRandom.alphanumeric(10),
            draft: draft
          )
          sale_page.save

          sale_page.product.shop.update!(template_variables: template_variables)

          if sale_page.errors.present?
            errors.merge!(sale_page.errors)
          end

          if responsible_staff
            if staff[:picture]
              responsible_staff.picture.purge
              responsible_staff.picture = staff[:picture]
            end
            responsible_staff.introduction = staff[:introduction]
            responsible_staff.save!
          end

          sale_page
        end
      end

      private

      def responsible_staff
        @responsible_staff ||= user.staffs.find(staff[:id]) if staff && staff[:id]
      end
    end
  end
end
