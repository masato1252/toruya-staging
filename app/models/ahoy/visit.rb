# == Schema Information
#
# Table name: ahoy_visits
#
#  id                      :bigint(8)        not null, primary key
#  visit_token             :string
#  visitor_token           :string
#  user_id                 :bigint(8)
#  ip                      :string
#  user_agent              :text
#  referrer                :text
#  referring_domain        :string
#  landing_page            :text
#  browser                 :string
#  os                      :string
#  device_type             :string
#  country                 :string
#  region                  :string
#  city                    :string
#  latitude                :float
#  longitude               :float
#  utm_source              :string
#  utm_medium              :string
#  utm_term                :string
#  utm_content             :string
#  utm_campaign            :string
#  app_version             :string
#  os_version              :string
#  platform                :string
#  started_at              :datetime
#  customer_social_user_id :string
#  owner_id                :string
#  product_id              :integer
#  product_type            :string
#
# Indexes
#
#  index_ahoy_visits_on_customer_social_user_id      (customer_social_user_id)
#  index_ahoy_visits_on_owner_id                     (owner_id)
#  index_ahoy_visits_on_product_type_and_product_id  (product_type,product_id)
#  index_ahoy_visits_on_user_id                      (user_id)
#  index_ahoy_visits_on_visit_token                  (visit_token) UNIQUE
#

class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :product, polymorphic: true, optional: true

  after_commit :visit_improvement

  def visit_improvement
    VisitImprovementJob.perform_later(self)
  end
end
