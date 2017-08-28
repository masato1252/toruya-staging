class CustomersPrintingJob < ApplicationJob
  queue_as :default

  def perform(super_user, filter_outcome, page_size, customer_ids)
    customers = super_user.customers.where(id: customer_ids).map do |customer|
      customer.with_google_contact
    end

    title = "#{filter_outcome.id}_#{Date.today.iso8601}"

    pdf_string = WickedPdf.new.pdf_from_string(
      ActionController::Base.new.render_to_string(
        :template => "customers/printing/index",
        :locals => {
          :@page_size => page_size,
          :@customers => customers,
        },
        :layout => "pdf"
      ),
      { :title => title }.merge!(Customers::PrintingConfig.run!(page_size: page_size))
    )

    pdf_path = Rails.root.join('tmp', "#{title}.pdf")
    File.open(pdf_path, 'wb') do |file|
      file << pdf_string
    end
    filter_outcome.file = File.open pdf_path

    if filter_outcome.save
      # Send Customers Printing Completed Email
      # NotificationMailer.customers_printing_finished(super_user).deliver_now
    else
      # What should we do
    end

    File.delete(pdf_path) if File.exist?(pdf_path)
  end
end
