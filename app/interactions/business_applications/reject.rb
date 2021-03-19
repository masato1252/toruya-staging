# frozen_string_literal: true

module BusinessApplications
  class Reject < ActiveInteraction::Base
    object :user

    def execute
      user.business_application.with_lock do
        user.business_application.rejected!

        BusinessApplicationMailer.with(business_application: user.business_application).applicant_rejected.deliver_later
      end
    end
  end
end
