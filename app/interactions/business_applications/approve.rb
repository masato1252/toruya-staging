module BusinessApplications
  class Approve < ActiveInteraction::Base
    object :user

    def execute
      user.business_application.with_lock do
        user.business_application.approved!

        BusinessApplicationMailer.with(business_application: user.business_application).applicant_approved.deliver_later
      end
    end
  end
end
