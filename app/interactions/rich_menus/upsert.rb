# frozen_string_literal: true

module RichMenus
  class Upsert < ActiveInteraction::Base
    object :social_account
    string :social_name, default: nil # nil is for create, update should have key
    file :image, default: nil # there is no real update in line rich menu, it is always creation
    boolean :current, default: false
    boolean :default, default: false

    string :internal_name
    string :bar_label
    string :layout_type # a, b etc...
    array :actions do
      hash do
        string :type # message, uri
        string :value
        string :desc, default: nil
      end
    end

    def execute
      key = social_name.presence || SecureRandom.uuid
      key = social_account.default_rich_menu_key if key == SocialAccounts::RichMenus::CustomerReservations::KEY

      body = compose(
        RichMenus::Body,
        internal_name: internal_name,
        bar_label: bar_label,
        layout_type: layout_type,
        actions: actions,
        key: key
      )

      compose(
        RichMenus::Create,
        social_account: social_account,
        internal_name: internal_name,
        bar_label: bar_label,
        body: body,
        key: key,
        image: image,
        current: current,
        default_menu: default
      )
    end
  end
end
