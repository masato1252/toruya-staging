class Customers::PrintingController < DashboardController
  PAGE_SIZE = {
    "a4" =>         { name: I18n.t("customer.printing_page_size.a4"),         width: 210, height: 297, top: 22, left: 20 },
    "postcard_a" => { name: I18n.t("customer.printing_page_size.postcard_a"), width: 100, height: 148, top: 32, left: 15 },
    "postcard_b" => { name: I18n.t("customer.printing_page_size.postcard_b"), width: 148, height: 100, top: 32, left: 75.5, right: 2.6 },
    "envelope" =>   { name: I18n.t("customer.printing_page_size.envelope"),   width: 235, height: 120, top: 32, left: 15 }
  }

  def new
    @customer = super_user.customers.find(params[:customer_id])
    @customer = if @customer.google_contact_id
                  @customer.build_by_google_contact(Customers::RetrieveGoogleContact.run!(customer: @customer))
                else
                  @customer
                end

    @page_size = params[:page_size]
    specified_size = PAGE_SIZE[@page_size]

    render :pdf => "customer",
      page_width: specified_size[:width],
      page_height: specified_size[:height],
      margin: {
        top: specified_size[:top],
        left: specified_size[:left],
        right: specified_size[:right] || 0,
        bottom: 0
      },
      title: @customer.name,
      layout: false
  end
end
