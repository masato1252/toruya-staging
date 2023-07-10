OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
end

# client = OpenAI::Client.new
# response = client.images.generate(parameters: { prompt: prompt, size: "512x512" })
# downloaded_image = URI.parse(response.dig("data", 0, "url")).open
# sale_page.picture.attach(io: downloaded_image, filename: File.basename(downloaded_image.path))
