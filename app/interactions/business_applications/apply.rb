module BusinessApplications
  class Apply < ActiveInteraction::Base
    object :user

    def execute
      application = user.business_application || user.build_business_application
      application.pending!

      AdminMailer.new_business_application.deliver_later
    end
  end
end
