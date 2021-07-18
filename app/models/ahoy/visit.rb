# == Schema Information
#
# Table name: ahoy_visits
#
#  id                      :bigint           not null, primary key
#  app_version             :string
#  browser                 :string
#  city                    :string
#  country                 :string
#  device_type             :string
#  ip                      :string
#  landing_page            :text
#  latitude                :float
#  longitude               :float
#  os                      :string
#  os_version              :string
#  platform                :string
#  product_type            :string
#  referrer                :text
#  referring_domain        :string
#  region                  :string
#  started_at              :datetime
#  user_agent              :text
#  utm_campaign            :string
#  utm_content             :string
#  utm_medium              :string
#  utm_source              :string
#  utm_term                :string
#  visit_token             :string
#  visitor_token           :string
#  customer_social_user_id :string
#  owner_id                :string
#  product_id              :integer
#  user_id                 :bigint
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
