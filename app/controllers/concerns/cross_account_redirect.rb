# frozen_string_literal: true

module CrossAccountRedirect
  extend ActiveSupport::Concern

  class_methods do
    def redirect_to_correct_owner_for(resource, param_key: :id, only: nil)
      before_action(only: only) do
        ensure_correct_owner(resource, params[param_key])
      end
    end
  end

  private

  def ensure_correct_owner(resource, resource_id)
    return if resource_id.blank?
    return if Current.business_owner.public_send(resource).exists?(id: resource_id)

    correct_owner = current_social_user&.manage_accounts&.find do |owner|
      owner.public_send(resource).exists?(id: resource_id)
    end

    if correct_owner
      redirect_to url_for(params.permit!.merge(business_owner_id: correct_owner.id))
    end
  end
end
