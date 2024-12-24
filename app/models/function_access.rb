# == Schema Information
#
# Table name: function_accesses
#
#  id               :bigint           not null, primary key
#  access_count     :integer          default(0), not null
#  access_date      :date             not null
#  action_type      :string
#  content          :string           not null
#  conversion_count :integer          default(0), not null
#  label            :string
#  revenue_cents    :integer          default(0), not null
#  source_type      :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  source_id        :string
#
# Indexes
#
#  index_function_accesses_on_content_source_and_date    (access_date,source_id,content)
#  index_function_accesses_on_date_and_source            (access_date,source_id,source_type)
#  index_function_accesses_on_date_and_source_and_label  (access_date,source_id,label)
#
class FunctionAccess < ApplicationRecord
  validates :content, presence: true
  validates :access_date, presence: true
  validates :content, uniqueness: { scope: [:source_type, :source_id, :access_date] }

  scope :by_date_range, ->(start_date, end_date) { where(access_date: start_date..end_date) }
  scope :by_source, ->(source) { where(source_type: source) }
  scope :by_source_id, ->(id) { where(source_id: id) }
  scope :by_action_type, ->(action) { where(action_type: action) }

  def self.track_access(content:, source_type: nil, source_id: nil, action_type: nil, label: nil)
    today = Time.current.to_date
    
    access = find_or_initialize_by(
      content: content,
      source_type: source_type,
      source_id: source_id,
      action_type: action_type,
      access_date: today,
      label: label
    )
    
    if access.new_record?
      access.save
    end
    
    if access.persisted?
      increment_counter(:access_count, access.id)
    end
    
    access
  end

  def self.track_conversion(content:, source_type: nil, source_id: nil, action_type: nil, revenue_cents: 0, label: nil)
    today = Time.current.to_date
    
    access = find_or_initialize_by(
      content: content,
      source_type: source_type,
      source_id: source_id,
      action_type: action_type,
      access_date: today,
      label: label
    )
    
    if access.new_record?
      access.save!
    end
    
    access.with_lock do
      access.increment!(:conversion_count)
      access.increment!(:revenue_cents, revenue_cents)
    end

    access
  end

  def self.total_clicks_for(content:, source_type: nil, source_id: nil, action_type: nil, start_date: nil, end_date: nil)
    scope = where(content: content)
    scope = scope.by_source(source_type) if source_type.present?
    scope = scope.by_source_id(source_id) if source_id.present?
    scope = scope.by_action_type(action_type) if action_type.present?
    scope = scope.by_date_range(start_date, end_date) if start_date && end_date
    scope.sum(:access_count)
  end

  def self.total_conversions_for(content:, source_type: nil, source_id: nil, action_type: nil, start_date: nil, end_date: nil)
    scope = where(content: content)
    scope = scope.by_source(source_type) if source_type.present?
    scope = scope.by_source_id(source_id) if source_id.present?
    scope = scope.by_action_type(action_type) if action_type.present?
    scope = scope.by_date_range(start_date, end_date) if start_date && end_date
    scope.sum(:conversion_count)
  end

  def self.total_revenue_for(content:, source_type: nil, source_id: nil, action_type: nil, start_date: nil, end_date: nil)
    scope = where(content: content)
    scope = scope.by_source(source_type) if source_type.present?
    scope = scope.by_source_id(source_id) if source_id.present?
    scope = scope.by_action_type(action_type) if action_type.present?
    scope = scope.by_date_range(start_date, end_date) if start_date && end_date
    scope.sum(:revenue_cents)
  end

  def self.metrics_for(source_id:, start_date:, end_date:)
    scope = where(source_id: source_id).where.not(label: nil).by_date_range(start_date, end_date)
    scope.pluck(:label).uniq.each_with_object({}) do |label, result|
      result[label] = {
        clicks: scope.where(label: label).sum(:access_count),
        conversions: scope.where(label: label).sum(:conversion_count), 
        revenue_cents: scope.where(label: label).sum(:revenue_cents)
      }
    end
  end

  def conversion_rate
    return 0 if access_count == 0
    (conversion_count.to_f / access_count * 100).round(2)
  end

  def average_order_value_cents
    return 0 if conversion_count == 0
    (revenue_cents.to_f / conversion_count).round
  end
end 
