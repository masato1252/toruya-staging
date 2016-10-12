# https://developers.google.com/google-apps/calendar/v3/reference/
class GoogleCalendarWrapper
  def initialize(current_user)
    configure_client(current_user)
  end

  def configure_client(current_user)
    @client = Google::APIClient.new
    @client.authorization.access_token = current_user.access_provider.access_token
    @client.authorization.refresh_token = current_user.access_provider.refresh_token
    @client.authorization.client_id = ENV['GOOGLE_CLIENT_ID']
    @client.authorization.client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @client.authorization.refresh!
    @service = @client.discovered_api('calendar', 'v3')
  end

  # array of calendar
  # {"kind"=>"calendar#calendarListEntry",
  #  "etag"=>"\"0\"",
  #  "id"=>"98l899n51a893d522v99d2pb5c@group.calendar.google.com",
  #  "summary"=>"自助旅行背包 客社團 行事曆",
  #  "description"=>"顯示社團聚會活動時間",
  #  "timeZone"=>"Asia/Taipei",
  #  "colorId"=>"2",
  #  "backgroundColor"=>"#d06b64",
  #  "foregroundColor"=>"#000000",
  #  "selected"=>true,
  #  "accessRole"=>"reader",
  #  "defaultReminders"=>[]
  #  }
  def calendars
    @calendars ||= begin
                     response = @client.execute(api_method: @service.calendar_list.list)
                     calendars = JSON.parse(response.body)
                     calendars["items"]
                   end
  end

  def calendar(calendar_id)
    calendars.select {|cal| cal["id"].downcase == calendar_id }
  end

  # array of event
  # {"kind"=>"calendar#event",
  #  "etag"=>"\"2819913253222000\"",
  #  "id"=>"90nm8677anlu85nk024vbl3s5s",
  #  "status"=>"confirmed",
  #  "htmlLink"=>"https://www.google.com/calendar/event?eid=OTBubTg2Nzdhbmx1ODVuazAyNHZibDNzNXMgOThsODk5bjUxYTg5M2Q1MjJ2OTlkMnBiNWNAZw",
  #  "created"=>"2011-05-01T06:29:16.000Z",
  #  "updated"=>"2014-09-05T22:37:06.611Z",
  #  "summary"=>"北區「以色列+埃及_LOCA」",
  #  "description"=>"FB上的活動網址:\nhttp://www.facebook.com/event.php?eid=185047948197919&index=1",
  #  "location"=>"台北行道會",
  #  "creator"=>{"email"=>"wendy688@gmail.com", "displayName"=>"Wendy Yang"},
  #  "organizer"=>{"email"=>"98l899n51a893d522v99d2pb5c@group.calendar.google.com",
  #                "displayName"=>"自助旅行背包客社團 行事曆",
  #                "self"=>true},
  #  "start"=>{"dateTime"=>"2011-05-14T14:00:00+08:00"},
  #  "end"=>{"dateTime"=>"2011-05-14T16:50:00+08:00"},
  #  "visibility"=>"public",
  #  "iCalUID"=>"90nm8677anlu85nk024vbl3s5s@google.com",
  #  "sequence"=>0,
  #  "reminders"=>{"useDefault"=>true}
  # }
  def events(calendar_id)
    response = @client.execute(api_method: @service.events.list, parameters: {calendarId: calendar_id})
    events = JSON.parse(response.body)
    events["items"]
  end
end
