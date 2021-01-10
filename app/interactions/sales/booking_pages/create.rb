module Sales
  module BookingPages
    class Create < ActiveInteraction::Base
      object :user
      integer :selected_booking_page
      integer :selected_template
      hash :template_variables, strip: false
      hash :product_content do
        file :picture
        string :desc1
        string :desc2
      end
      hash :staff do
        integer :id
        file :picture, default: nil
        string :introduction
      end
      array :flow do
        string
      end

      def execute
        ApplicationRecord.transaction do
          picture = product_content.delete(:picture)

          sale_page = user.sale_pages.create(
            product_id: selected_booking_page,
            product_type: "BookingPage",
            sale_template_id: selected_template,
            sale_template_variables: template_variables,
            picture: picture,
            content: product_content,
            flow: flow,
            staff: responsible_staff
          )

          sale_page.product.shop.update!(template_variables: template_variables)

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
