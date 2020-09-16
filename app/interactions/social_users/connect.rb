module SocialUsers
  class Connect < ActiveInteraction::Base
    object :user
    object :social_user

    def execute
      social_user.update!(user: user)
    end
  end
end
