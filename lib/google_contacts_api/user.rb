require "google_contacts_api/contact"
require "google_contacts_api/group"
require "google_contacts_api/client"

module GoogleContactsApi
  class User
    include GoogleContactsApi::Contact
    include GoogleContactsApi::Group
    attr_reader :client

    def initialize(user)
      @client = GoogleContactsApi::Client.new(user).client
    end
  end
end
