class CustomersPrintingJob < ApplicationJob
  queue_as :default

  def perform(super_user, page_size, customer_ids)
    customers = super_user.customers.where(id: customer_ids).map do |customer|
      if customer.google_contact_id
        customer.build_by_google_contact(Customers::RetrieveGoogleContact.run!(customer: customer))
      else
        customer
      end
    end

    specified_size = Customers::PrintingController::PAGE_SIZE[page_size]
    title = customers.first.name

    pdf_string = WickedPdf.new.pdf_from_string(
      ActionController::Base.new.render_to_string(
        :template => "customers/printing/index",
        :locals => {
          :@page_size => page_size,
          :@customers => customers,
        },
        :layout => "pdf"
      ),
      :page_width => specified_size[:width],
      :page_height => specified_size[:height],
      :margin => {
        :top => specified_size[:top],
        :left => specified_size[:left],
        :right => specified_size[:right] || 0,
        :bottom => 0
      },
      :title => title,
    )

    tempfile = Tempfile.new([title, ".pdf"], Rails.root.join('tmp'))
    tempfile.binmode
    tempfile.write pdf_string
    tempfile.close

    # if outcome.valid?
      # Send Customers Printing Completed Email
      # NotificationMailer.customers_printing_finished(super_user).deliver_now
    # else
      # What should we do
    # end
  end
end
