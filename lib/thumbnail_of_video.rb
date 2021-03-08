# https://github.com/cookpete/react-player/blob/994820ee53f2f0b1b4afd95c7484b27bf81cda84/src/Preview.js#L39-L48
module ThumbnailOfVideo
  def self.get(url)
    begin
      response = URI.open("https://noembed.com/embed?url=#{url}").read

      result = JSON.parse(response)

      if result && result["thumbnail_url"]
        result["thumbnail_url"].sub('height=100', 'height=480')
      end
    rescue StandardError
      nil
    end
  end
end
