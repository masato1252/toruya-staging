# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocialRichMenu do
  describe '#actions' do
    it 'returns expected result' do
      body = {
        'name' => 'デフォルト',
        'size' => { 'width' => 2500, 'height' => 1686 },
        'areas' =>
        [
          { 'action' => { 'text' => '全ての予約', 'type' => 'message', 'label' => '全ての予約' },
            'bounds' => { 'x' => 0, 'y' => 0, 'width' => 833, 'height' => 843 } },
          { 'action' => { 'text' => '新たに予約する', 'type' => 'message', 'label' => '新たに予約する' },
            'bounds' => { 'x' => 834, 'y' => 0, 'width' => 833, 'height' => 843 } },
          { 'action' => { 'text' => 'お問い合わせ', 'type' => 'message', 'label' => 'お問い合わせ' },
            'bounds' => { 'x' => 1667, 'y' => 0, 'width' => 833, 'height' => 843 } },
          {
            'action' => { 'uri' => 'https://toruya-staging.herokuapp.com/sale_pages/44', 'type' => 'uri',
                          'label' => 'sale_page' }, 'bounds' => { 'x' => 0, 'y' => 843, 'width' => 833, 'height' => 843 }
          },
          { 'action' => { 'text' => 'foo', 'type' => 'message', 'label' => 'foo' },
            'bounds' => { 'x' => 834, 'y' => 843, 'width' => 833, 'height' => 843 } },
          { 'action' => { 'uri' => 'https://foo.com', 'type' => 'uri', 'label' => 'bar' }, 'bounds' => { 'x' => 1667, 'y' => 843, 'width' => 833, 'height' => 843 } }
        ],
        'selected' => true,
        'chatBarText' => '予約する↓'
      }
      social_rich_menu = SocialRichMenu.new(body:)

      expect(social_rich_menu.actions).to eq(
        [
          { type: :incoming_reservations, value: :incoming_reservations },
          { type: :booking_pages, value: :booking_pages },
          { type: :contacts, value: :contacts },
          { type: 'sale_page', value: 'https://toruya-staging.herokuapp.com/sale_pages/44' },
          { type: 'text', value: 'foo', desc: 'foo' },
          { type: 'uri', value: 'https://foo.com', desc: 'bar' }
        ]
      )
    end
  end
end
