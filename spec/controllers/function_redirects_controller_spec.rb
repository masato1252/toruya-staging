require 'rails_helper'

RSpec.describe FunctionRedirectsController, type: :controller do
  describe '#redirect' do
    let(:url) { 'https://example.com' }
    let(:source_type) { 'rich_menu' }
    let(:source_id) { '123' }
    let(:action_type) { 'click' }
    let(:label) { 'foo' }
    let(:params) do
      {
        content: url,
        source_type: source_type,
        source_id: source_id,
        action_type: action_type,
        label: label
      }
    end

    it 'tracks the function access' do
      expect {
        get :redirect, params: params
      }.to change(FunctionAccess, :count).by(1)

      last_access = FunctionAccess.last
      expect(last_access.content).to eq(url)
      expect(last_access.source_type).to eq(source_type)
      expect(last_access.source_id).to eq(source_id)
      expect(last_access.action_type).to eq(action_type)
      expect(last_access.label).to eq(label)
      expect(response).to redirect_to("#{url}?function_access_id=#{FunctionAccess.last.id}")
    end

    context 'with missing parameters' do
      let(:params) { { content: url } }

      it 'still performs the redirect' do
        get :redirect, params: params

        expect(response).to redirect_to(url)
      end
    end
  end
end 
