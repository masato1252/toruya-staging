require 'rails_helper'

RSpec.describe Equipments::Upsert do
  let(:user) { FactoryBot.create(:user) }
  let(:shop) { FactoryBot.create(:shop, user: user) }
  let(:menu1) { FactoryBot.create(:menu, user: user, shop: shop) }
  let(:menu2) { FactoryBot.create(:menu, user: user, shop: shop) }

  describe '.run' do
    it 'creates a new equipment with menu associations' do
      args = {
        shop: shop,
        name: 'Test Equipment',
        quantity: 3,
        equipment_menus: [
          { menu_id: menu1.id, checked: true, required_quantity: 2 },
          { menu_id: menu2.id, checked: false, required_quantity: 1 }
        ]
      }
      expect {
        outcome = described_class.run(args)
        expect(outcome).to be_valid
        equipment = outcome.result
        expect(equipment.name).to eq('Test Equipment')
        expect(equipment.quantity).to eq(3)
        expect(equipment.menu_equipments.count).to eq(1)
        me = equipment.menu_equipments.first
        expect(me.menu_id).to eq(menu1.id)
        expect(me.required_quantity).to eq(2)
      }.to change { Equipment.count }.by(1)
        .and change { MenuEquipment.count }.by(1)
    end

    it 'updates an existing equipment and its menu associations' do
      equipment = FactoryBot.create(:equipment, shop: shop, name: 'Old Name', quantity: 1)
      FactoryBot.create(:menu_equipment, equipment: equipment, menu: menu1, required_quantity: 1)
      args = {
        shop: shop,
        equipment: equipment,
        name: 'Updated Name',
        quantity: 5,
        equipment_menus: [
          { menu_id: menu2.id, checked: true, required_quantity: 4 }
        ]
      }
      expect {
        outcome = described_class.run(args)
        expect(outcome).to be_valid
        equipment.reload
        expect(equipment.name).to eq('Updated Name')
        expect(equipment.quantity).to eq(5)
        expect(equipment.menu_equipments.count).to eq(1)
        me = equipment.menu_equipments.first
        expect(me.menu_id).to eq(menu2.id)
        expect(me.required_quantity).to eq(4)
      }.to change { MenuEquipment.count }.by(0) # delete first then add
    end

    it 'does not create equipment with invalid params' do
      args = {
        shop: shop,
        name: '',
        quantity: 0
      }
      outcome = described_class.run(args)
      expect(outcome).not_to be_valid
      expect(outcome.errors[:base].join).to match(/Name|Quantity/)
    end
  end
end