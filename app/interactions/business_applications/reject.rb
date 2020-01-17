module BusinessApplications
  class Reject < ActiveInteraction::Base
    object :user

    def execute
      user.business_application.rejected!
    end
  end
end
