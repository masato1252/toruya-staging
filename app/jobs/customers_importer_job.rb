class CustomersImporterJob < ApplicationJob
  queue_as :default

  def perform(contact_group, notify = false)
    outcome = Customers::Import.run(contact_group: contact_group)

    if outcome.valid?
      # Send Synchronization Completed Email
      NotificationMailer.customers_import_finished(contact_group).deliver_now if notify
    else
      # What should we do
    end
  end
end
