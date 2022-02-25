require "thumbnail_of_video"

module ContentHelper
  PDF_LOGO_URL = "https://toruya.s3-ap-southeast-1.amazonaws.com/public/pdf_logo.png"

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
        PDF_LOGO_URL
      else
      end
  end
end
