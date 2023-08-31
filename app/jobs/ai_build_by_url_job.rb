# frozen_string_literal: true

class AiBuildByUrlJob < ApplicationJob
  queue_as :low_priority

  def perform(user_id, url)
    if is_sitemap_url?(url)
      links = get_all_links_from_sitemap(url)

      links.each do |link|
        AiBuildByUrlJob.perform_later(user_id, link)
      end
    else
      AI_BUILD.build_by_url(user_id, url)
    end
  end

  private

  def is_sitemap_url?(url)
    doc = doc_of_url(url)
    doc.root && doc.root.name.downcase == 'urlset'
  rescue OpenURI::HTTPError
    false
  end

  def get_all_links_from_sitemap(url)
    doc = doc_of_url(url)
    doc.xpath('//xmlns:loc').map(&:text)
  end

  def doc_of_url(url)
    @doc ||=
      begin
        response = URI.open(url)
        Nokogiri::XML(response)
      end
  end
end
