# frozen_string_literal: true

module SalePages
  class Update < ActiveInteraction::Base
    object :sale_page
    string :update_attribute

    hash :attrs, default: nil do
      hash :sale_template_variables, strip: false, default: nil
      string :internal_name, default: nil
      string :introduction_video_url, default: nil
      string :selling_end_at, default: nil
      string :selling_start_at, default: nil
      integer :quantity, default: nil
      integer :selling_price, default: nil
      integer :monthly_price, default: nil
      integer :yearly_price, default: nil
      hash :selling_multiple_times_price, default: nil do
        integer :times, default: nil
        integer :amount, default: nil
      end
      integer :normal_price, default: nil
      hash :why_content, default: nil do
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
      array :benefits, default: nil do
        string
      end
      array :faq, default: nil do
        hash do
          string :answer
          string :question
        end
      end
      array :reviews, default: nil do
        hash do
          file :picture, default: nil
          string :filename, default: nil
          string :customer_name
          string :content
        end
      end
    end

    def execute
      sale_page.with_lock do
        case update_attribute
        when "sale_template_variables", "flow", "quantity", "internal_name"
          sale_page.update(attrs.slice(update_attribute))
        when "introduction_video_url"
          sale_page.update(introduction_video_url: attrs[:introduction_video_url].presence)
        when "benefits", "faq"
          sale_page.sections_context ||= {}
          sale_page.sections_context.merge!(attrs.slice(update_attribute))
          sale_page.save
        when "reviews"
          sale_page.sections_context ||= {}
          Array.wrap(attrs[update_attribute]).each do |attr|
            if picture = attr.delete(:picture)
              sale_page.customer_pictures.attach(io: picture, filename: picture.original_filename)
              attr.merge!(filename: picture.original_filename)
            end
          end

          sale_page.sections_context.merge!(attrs.slice(update_attribute))
          # TODO: handle purge
          sale_page.save
        when "normal_price"
          sale_page.update(normal_price_amount_cents: attrs[:normal_price])
        when "selling_price"
          sale_page.update(selling_price_amount_cents: attrs[:selling_price])

          if attrs[:selling_multiple_times_price].present?
            sale_page.update(
              selling_multiple_times_price: Array.new(
                attrs[:selling_multiple_times_price][:times].to_i,
                attrs[:selling_multiple_times_price][:amount].to_i
              )
            )
          else
            sale_page.update(selling_multiple_times_price: [])
          end

          if attrs[:monthly_price].present? || attrs[:yearly_price].present?
            compose(SalePages::UpdateRecurringPrice, sale_page: sale_page, interval: "month", amount: attrs[:monthly_price].presence || 0)
            compose(SalePages::UpdateRecurringPrice, sale_page: sale_page, interval: "year", amount: attrs[:yearly_price].presence || 0)
          end
        when "why_content"
          picture = attrs[:why_content].delete(:picture)

          sale_page.update(content: attrs[:why_content])
          if picture
            sale_page.picture.purge_later
            sale_page.update(picture: picture)
          end
        when "end_time"
          sale_page.update(selling_end_at: attrs[:selling_end_at] ? Time.zone.parse(attrs[:selling_end_at]).end_of_day : nil)
        when "start_time"
          sale_page.update(selling_start_at: attrs[:selling_start_at] ? Time.zone.parse(attrs[:selling_start_at]).beginning_of_day : nil)
        when "staff"
          responsible_staff = sale_page.user.staffs.find(attrs[:staff][:id])
          sale_page.update(staff: responsible_staff)
          if attrs[:staff][:picture]
            responsible_staff.picture.purge
            responsible_staff.picture = attrs[:staff][:picture]
          end
          responsible_staff.introduction = attrs[:staff][:introduction]
          responsible_staff.save!
        end

        if sale_page.errors.present?
          errors.merge!(sale_page.errors)
        end
      end

      sale_page
    end
  end
end
