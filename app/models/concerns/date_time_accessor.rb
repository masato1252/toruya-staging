# frozen_string_literal: true

# example:
# date_time_accessor :start_time, :end_time
# will generate below code
#
# attr_accessor :start_at_date_part, :start_at_time_part
# before_validation :set_start_at
#
# def set_start_at
#   if start_at_date_part && start_at_time_part
#     self.start_at = Time.zone.parse("#{start_at_date_part}-#{start_at_time_part}")
#   end
# end
#
# def start_at_date
#   start_at.to_fs(:date)
# end
#
# def start_at_time
#   start_at.to_fs(:time)
# end
#
# options:
#   accessor_only, default: nil
#   won't create before_validation and set_xxx
#
module DateTimeAccessor
  extend ActiveSupport::Concern

  module ClassMethods
    def date_time_accessor(*time_attributes)
      options = time_attributes.extract_options!

      time_attributes.each do |time_attribute|
        attr_accessor "#{time_attribute}_date_part", "#{time_attribute}_time_part"

        unless options[:accessor_only]
          set_callback :validation, :before, "set_#{time_attribute}".to_sym

          define_method("set_#{time_attribute}") do
            if public_send("#{time_attribute}_date_part") && public_send("#{time_attribute}_time_part")
              self.public_send("#{time_attribute}=", Time.zone.parse("#{public_send("#{time_attribute}_date_part")}-#{public_send("#{time_attribute}_time_part")}"))
            else
              self.public_send("#{time_attribute}=", nil)
            end
          end
        end

        define_method("#{time_attribute}_date") do
          public_send(time_attribute).to_fs(:date) if public_send(time_attribute)
        end

        define_method("#{time_attribute}_time") do
          public_send(time_attribute).to_fs(:time) if public_send(time_attribute)
        end
      end
    end
  end
end
