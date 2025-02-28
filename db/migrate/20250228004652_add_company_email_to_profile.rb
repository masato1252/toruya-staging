class AddCompanyEmailToProfile < ActiveRecord::Migration[7.0]
  def change
    add_column :profiles, :company_email, :string

    # Use Shop data to overwrite the company
    User.find_each do |user|
      if user.profile.present? && user.shops.exists?
        shop = user.shops.first

        user.profile.update!(
          company_name: shop.name,
          company_phone_number: shop.phone_number,
          company_email: shop.email,
          company_zip_code: shop.zip_code,
          company_address: shop.address,
          company_address_details: shop.address_details,
          website: shop.website
        )

        if shop.logo.attached?
          begin
            content_picture = URI.open(Rails.application.routes.url_helpers.url_for(shop.logo))
            user.profile.logo.attach(io: content_picture, filename: shop.logo.blob.filename.to_s) if content_picture.present?
            user.profile.save!
          rescue StandardError
            content_picture = nil
          end
        end
      end
    end

    OnlineService.where(company_type: "Shop").find_each do |online_service|
      online_service.update!(company: online_service.user.profile)
    end
  end
end
