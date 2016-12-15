class CustomersImporterJob < ApplicationJob
  queue_as :default

  def perform(contact_group)
    outcome = Customers::Import.run(contact_group: contact_group)

    if outcome.valid?
      # Send Synchronization Completed Email
      NotificationMailer.customers_import_finished(contact_group).deliver_now
    else
      # What should we do
    end
  end
end
