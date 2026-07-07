# frozen_string_literal: true

# When COMPAT_API_READ_ENABLED=true, list/detail actions must not load business
# data via ActiveRecord. Data comes from v1 compat read APIs (compatRead in webpack).
#
# See toruya-next: doc/phase2/03-legacy-db-independence-roadmap.md
module CompatReadSkipsBusinessData
  extend ActiveSupport::Concern
  include CompatReadFlags

  class_methods do
    def skip_business_data_load_on_compat_read(*actions)
      before_action :assert_compat_read_skips_business_ar!, only: actions
    end
  end

  private

  def assert_compat_read_skips_business_ar!
    return unless compat_read_data_plane?

    # Hook for future: fail fast if @ivar business collections were set in action.
    # Controllers should return early after assigning empty placeholders.
  end
end
