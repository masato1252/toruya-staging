# frozen_string_literal: true

Warden::Manager.after_set_user do |user,auth,opts|
  scope = opts[:scope]
  auth.cookies.delete("#{scope}.id")
  auth.cookies.signed["#{scope}.id"] = {
    value: user.id,
    domain: :all
  }
end

Warden::Manager.before_logout do |user, auth, opts|
  scope = opts[:scope]
  auth.cookies.signed["#{scope}.id"] = {
    value: nil,
    domain: :all
  }
end
