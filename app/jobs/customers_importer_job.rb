class CustomersImporterJob < ApplicationJob
  queue_as :default

  def perform(contact_group)
    outcome = Customers::ImportCustomers.run(contact_group: contact_group)

    if outcome.valid?
      # Send Synchronization Completed Email
    else
      # What should we do
    end
  end
end
