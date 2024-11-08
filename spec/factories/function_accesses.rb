FactoryBot.define do
  factory :function_access do
    content { "https://example.com" }
    source_type { "sale_page" }
    source_id { "123" }
    action_type { "click" }
    access_date { Date.current }
    access_count { 0 }
    conversion_count { 0 }
    revenue_cents { 0 }
  end
end 