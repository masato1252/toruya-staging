namespace :validations do
  task :google_contact_api => :environment do
    begin
      client = Slack::Web::Client.new
      user = User.find_by(email: "lake.ilakela@gmail.com")
      contact_group_id = user.contact_groups.connected.first.id
      rank_id = user.ranks.first.id

      params = {"contact_group_id"=>contact_group_id, "rank_id"=>rank_id, "phonetic_last_name"=>"444444", "phonetic_first_name"=>"555555", "last_name"=>"666666", "first_name"=>"77777777", "primary_phone"=>"home-=-22222222", "primary_email"=>"home-=-3333333333", "primary_address"=>{"type"=>"home", "postcode1"=>"888", "postcode2"=>"888", "region"=>"北海道", "city"=>"999999", "street1"=>"000000", "street2"=>"111111"}, "phone_numbers"=>[{"type"=>"home", "value"=>"22222222"}], "emails"=>[{"type"=>"home", "value"=>{"address"=>"3333333333"}}], "custom_id"=>"4444444", "dob"=>{"year"=>"1916", "month"=>"1", "day"=>"1"}, "memo"=>"555555555"}.with_indifferent_access

      # create
      outcome = Customers::Save.run!(user: user, current_user: user, params: params.dup)

      # update
      customer = Customers::Save.run!(user: user, current_user: user, params: params.merge!("id": outcome.result.id))

      # destroy
      customer.reload.destroy!
      puts "Done. validations:google_contact_api"

      client.chat_postMessage(channel: 'development', text: "[OK] Google Contact Api Test successfully")
    rescue => e
      client.chat_postMessage(channel: 'development', text: "[ALERTING] Google Contact Api Test failed")
      Rollbar.error(e)
      raise e
    end
  end
end
