# frozen_string_literal: true

class CompatStaffAccountProxy
  def initialize(session_data, owner_id)
    @session_data = session_data
    @owner_id = owner_id
  end

  def present?
    return true if @session_data["owner_id"].to_i == @owner_id.to_i

    @session_data["staff_id"].present?
  end

  def staff_id
    @session_data["staff_id"]
  end

  def owner_id
    @owner_id
  end
end

class CompatStaffProxy
  def initialize(staff_id)
    @staff_id = staff_id
  end

  def id
    @staff_id
  end

  def present?
    @staff_id.present?
  end
end

# Lightweight stand-in for User when COMPAT_API_READ_ENABLED — avoids social_user / staff_accounts AR reads.
class CompatCurrentUser
  attr_reader :session_data

  def initialize(session_data)
    @session_data = session_data
  end

  def id
    session_data["current_user_id"]
  end

  def current_staff_account(owner = nil)
    owner_id = owner.is_a?(CompatBusinessOwner) ? owner.id : owner&.id
    return nil unless owner_id

    CompatStaffAccountProxy.new(session_data, owner_id)
  end

  def current_staff(_owner = nil)
    staff_id = session_data["staff_id"]
    return nil unless staff_id

    CompatStaffProxy.new(staff_id)
  end

  def staff_accounts
    CompatStaffAccountsRelation.new(session_data)
  end

  def profile
    return @profile if defined?(@profile)

    @profile =
      if session_data["shop_profile_complete"]
        OpenStruct.new(company_address_details: { "compat" => true })
      end
  end

  def super_admin?
    session_data["is_super_admin"] == true
  end

  def can_admin_chat?
    session_data["can_admin_chat"] == true
  end

  def ==(other)
    case other
    when User
      id == other.id
    when CompatCurrentUser
      id == other.id
    else
      false
    end
  end

  def is_a?(klass)
    klass == User || super
  end

  def ar_user
    @ar_user ||= User.find_by(id: id)
  end

  def method_missing(method_name, *args, &block)
    if ar_user.respond_to?(method_name)
      ar_user.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    ar_user.respond_to?(method_name, include_private) || super
  end
end

class CompatStaffAccountsRelation
  def initialize(session_data)
    @session_data = session_data
  end

  def active
    self
  end

  def where(conditions = nil)
    return self if conditions.blank?

    if conditions.is_a?(Hash) && conditions.key?(:owner_id)
      owner_id = conditions[:owner_id]
      if owner_id.to_i != @session_data["owner_id"].to_i && @session_data["works_as_external_staff"]
        return CompatStaffAccountsRelation.new(@session_data.merge("_external_only" => true))
      end
    end

    self
  end

  def not(conditions)
    if conditions.is_a?(Hash) && conditions.key?(:owner_id)
      return self unless @session_data["works_as_external_staff"]
    end

    self
  end

  def exists?
    return false if @session_data["_external_only"]

    @session_data["works_as_external_staff"] == true
  end
end
