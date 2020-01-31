module BusinessApplications
  class Apply < ActiveInteraction::Base
    object :user

    def execute
      application = user.business_application || user.build_business_application
      application.with_lock do
        application.pending!

        AdminMailer.new_business_application.deliver_later
        BusinessApplicationMailer.with(business_application: application).applicant_applied.deliver_later
      end
    end
  end
end
