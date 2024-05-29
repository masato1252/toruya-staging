# frozen_string_literal: true

module Consultants
  class Invite < ActiveInteraction::Base
    object :consultant_user, class: User
    string :phone_number

    def execute
      consultant_account = ConsultantAccount.find_or_initialize_by(consultant_user: consultant_user, phone_number: phone_number)
      consultant_account.token = Digest::SHA1.hexdigest("#{Time.now.to_i}-#{SecureRandom.random_number}")
      consultant_account.save

      # Send SMS to invitee to tell them come to be a staff
      Notifiers::Users::Notifications::InviteConsultantClient.run(receiver: consultant_account)
    end
  end
end
