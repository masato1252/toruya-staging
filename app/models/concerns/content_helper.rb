# frozen_string_literal: true

require "thumbnail_of_video"

module ContentHelper
  PDF_THUMBNAIL_URL = "https://toruya.s3.ap-southeast-1.amazonaws.com/public/linethumb_pdf.png"
  VIDEO_THUMBNAIL_URL = "https://toruya.s3.ap-southeast-1.amazonaws.com/public/linethumb_video.png"
  BUNDLER_THUMBNAIL_URL = "https://toruya.s3.ap-southeast-1.amazonaws.com/public/linethumb_bundle.png"

  def thumbnail_url
    @thumbnail_url ||=
      case solution_type
      when "video"
        if content_url
          url = begin
            VideoThumb::get(content_url, "medium")
          rescue URI::InvalidURIError
          end

          # Line doesn't accept http url anyway, so we always force it to https
          (url || ThumbnailOfVideo.get(content_url))&.gsub("http:", "https:")

        end
      when "pdf"
        PDF_THUMBNAIL_URL
      else
      end
  end
end
