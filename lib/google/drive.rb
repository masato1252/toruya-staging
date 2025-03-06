require "google_drive"

module Google
  class Drive
    def self.spreadsheet(google_sheet_id: "1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg", gid: nil)
      raw_config_content = File.read(Rails.root.join('config/google_session_config.json'))
      temp_config = Tempfile.open("config", binmode: true)
      temp_config.write(ERB.new(raw_config_content).result)
      temp_config.rewind

      session = GoogleDrive::Session.from_config(temp_config.path)
      session.spreadsheet_by_key(google_sheet_id).worksheet_by_gid(gid)
    end
  end
end
