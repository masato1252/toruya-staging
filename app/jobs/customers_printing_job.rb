class CustomersPrintingJob < ApplicationJob
  queue_as :default

  def perform(filter_outcome, page_size, customer_ids)
    super_user = filter_outcome.user

    customers = super_user.customers.where(id: customer_ids).map do |customer|
      customer.with_google_contact
    end

    title = "#{super_user.filter_outcomes.count + 1}_#{Date.today.iso8601}"

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
      filter_outcome.complete!
      NotificationMailer.customers_printing_finished(super_user).deliver_now
    else
      filter_outcome.fail!
    end

    File.delete(pdf_path) if File.exist?(pdf_path)
  rescue => e
    filter_outcome.fail!
    Rollbar.error(e, filter_outcome_id: filter_outcome.id)
  end
end
