# frozen_string_literal: true

module Utils
  def self.bi_weekly_monday(date)
    start_date = Date.new(2023, 1, 1)
    monday = date.beginning_of_week
    weeks_since_start = ((monday - start_date).to_i / 7) + 1
    bi_weekly = weeks_since_start % 2 == 0
    bi_weekly_monday = monday && bi_weekly
  end

  def self.file_from_url(url)
    response = URI.open(url)
    filename = response.meta['content-disposition'].match(/filename=(["'])?([^'"]+)["']?/)[2] if response.meta['content-disposition']
    content_type = response.meta['content-type']
    tempfile = Tempfile.new([filename, File.extname(filename)])
    tempfile.binmode
    tempfile.write(response.read)
    tempfile.rewind
    tempfile
  end

  def self.url_with_external_browser(url)
    return url unless url =~ URI::regexp

    uri = URI.parse(url)
    query = if uri.query
              CGI.parse(uri.query)
            else
              {}
            end

    query['openExternalBrowser'] = %w(1)
    uri.query = URI.encode_www_form(query)
    uri.to_s
  rescue URI::InvalidURIError
    url
  end
end
