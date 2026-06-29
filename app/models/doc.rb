# frozen_string_literal: true

class Doc < ApplicationRecord
  has_many :doc_downloads, dependent: :destroy

  has_one_attached :thumbnail

  enum status: { unpublished: 0, published: 1 }, _prefix: :status

  validates :title, presence: true
  validates :document_url, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, on: :create

  scope :undeleted, -> { where(deleted_at: nil) }
  scope :active, -> { undeleted }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def public_url
    Rails.application.routes.url_helpers.doc_url(slug: slug, host: default_host)
  end

  private

  def assign_slug
    return if slug.present?

    self.slug = loop do
      candidate = SecureRandom.alphanumeric(12)
      break candidate unless Doc.exists?(slug: candidate)
    end
  end

  def default_host
    Rails.application.config.action_mailer.default_url_options&.fetch(:host, "localhost")
  end
end
