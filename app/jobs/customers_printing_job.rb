class CustomersPrintingJob < ApplicationJob
  queue_as :default

  def perform(filtered_outcome, customer_ids)
    super_user = filtered_outcome.user
    page_size = filtered_outcome.page_size

    customers = super_user.customers.where(id: customer_ids)
    customers = case filtered_outcome.outcome_type
                when FilteredOutcome::OUTCOME_TYPES.first
                  customers.map(&:with_google_contact)
                when FilteredOutcome::OUTCOME_TYPES.second
                  customers.includes(:contact_group, :rank)
                end

    title = "#{super_user.filtered_outcomes.count + 1}_#{Date.today.iso8601}"

    pdf_string = WickedPdf.new.pdf_from_string(
      ActionController::Base.new.render_to_string(
        :template => "customers/printing/#{filtered_outcome.outcome_type}",
        :locals => {
          :@page_size => page_size,
          :@customers => customers,
          :@filter_name => filtered_outcome.filter.try(:name),
        },
        :layout => "pdf"
      ),
      { :title => title, disposition: "attachment" }.merge!(Customers::PrintingConfig.run!(page_size: page_size))
    )

    pdf_path = Rails.root.join('tmp', "#{title}.pdf")
    File.open(pdf_path, 'wb') do |file|
      file << pdf_string
    end
    filtered_outcome.file = File.open pdf_path

    if filtered_outcome.save
      filtered_outcome.complete!
      NotificationMailer.customers_printing_finished(filtered_outcome).deliver_now
    else
      filtered_outcome.fail!
    end

    File.delete(pdf_path) if File.exist?(pdf_path)
  rescue => e
    filtered_outcome.fail!
    Rollbar.error(e, filtered_outcome_id: filtered_outcome.id)
    raise e if Rails.env.development?
  end
end
