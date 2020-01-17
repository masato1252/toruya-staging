module BusinessApplications
  class Approve < ActiveInteraction::Base
    object :user

    def execute
      user.business_application.approved!
    end
  end
end
