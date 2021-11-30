require "thumbnail_of_video"

module ContentHelper
  PDF_LOGO_URL = "https://toruya.s3-ap-southeast-1.amazonaws.com/public/pdf_logo.png"

  def thumbnail_url
    @thumbnail_url ||=
      case solution_type
      when "video"
        VideoThumb::get(content_url, "medium") || ThumbnailOfVideo.get(content_url) if content_url
      when "pdf"
        PDF_LOGO_URL
      else
      end
  end
end
