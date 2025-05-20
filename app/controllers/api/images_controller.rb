require 'mini_magick'

class Api::ImagesController < ApplicationController
  def create
    image = params[:image]

    if image.present?
      # Check image dimensions
      image_metadata = MiniMagick::Image.new(image.tempfile.path)
      width = image_metadata.width

      # Only resize if width is greater than 800px
      if width > 800
        # Create a temporary file for the resized image
        image_metadata.resize "800x" # Maintain aspect ratio
        temp_file = Tempfile.new(['resized_image', File.extname(image.original_filename)])
        image_metadata.write(temp_file.path)

        # Store the resized image using Active Storage
        blob = ActiveStorage::Blob.create_and_upload!(
          io: File.open(temp_file.path),
          filename: image.original_filename,
          content_type: image.content_type
        )

        # Clean up temporary file
        temp_file.close
        temp_file.unlink
      else
        # Store original image if width is 800px or less
        blob = ActiveStorage::Blob.create_and_upload!(
          io: image,
          filename: image.original_filename,
          content_type: image.content_type
        )
      end

      # Generate URL for the image
      image_url = url_for(blob)

      render json: { success: true, data: { link: image_url } }
    else
      render json: { success: false, message: 'No image provided' }, status: :unprocessable_entity
    end
  end
end
