module RichMenus
  class Upsert < ActiveInteraction::Base
    object :social_account
    string :key, default: nil # nil is for create, update should have key
    file :image # there is no real update in line rich menu, it is always creation

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
      body = compose(
        RichMenus::Body,
        internal_name: internal_name,
        bar_label: bar_label,
        layout_type: layout_type,
        actions: actions
      )

      compose(
        RichMenus::Create,
        social_account: social_account,
        body: body,
        key: key || SecureRandom.uuid,
        image: image
      )
    end
  end
end
