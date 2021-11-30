class AddContentUrlToOnlineService < ActiveRecord::Migration[6.0]
  def change
    add_column :online_services, :content_url, :string

    OnlineService.find_each do |online_service|
      online_service.update(content_url: online_service.content&.dig("url"))
    end
  end
end
