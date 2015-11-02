require 'spec_helper'

describe_admin_controller Admin::AdministrationsController do
  before(:all) { logged_in_as(:super_user) }

  describe '#index' do
    context 'with some administrations' do
      let!(:active_administration) { Factory(:administration, :site => current_site, :active => true) }
      let!(:inactive_administration) { Factory(:administration, :site => current_site, :active => false) }

      it 'should retrieve active administrations' do
        get '/en/administrations'
        expect(response).to be_ok
        expect(assigns(:administrations)).to have(2).items
      end

      it 'should filter' do
        get '/en/administrations', :scope_filter => ['archived']
        expect(response).to be_ok
        expect(assigns(:administrations)).to eq([inactive_administration])
      end
    end
  end

  describe '#new' do
    it 'should build an administration' do
      get '/en/administrations/new'
      expect(response).to be_ok
      expect(assigns(:administration)).to be_new_record
    end
  end

  describe '#create' do
    it 'should create an administration' do
      post '/en/administrations', :administration => { :name => 'batman' }
      expect(response).to be_ok
      administration = assigns(:administration)
      expect(administration).to_not be_new_record
      expect(administration.name).to eq('batman')
      expect(administration.site_id).to eq(current_site.id)
    end
  end

  context 'with an active administration' do
    let(:administration) { Factory(:administration, :site => current_site, :active => true) }

    describe '#update' do
      it 'should update the administration' do
        expect(administration.name).to_not eq('batman')
        put "/en/administrations/#{administration.to_param}", :administration => { :name => 'batman' }
        expect(response).to be_redirected_to('http://admin.test/en/administrations')
        expect(administration.reload.name).to eq('batman')
      end
    end

    describe '#archive' do
      it 'should archive the administration' do
        post "/en/administrations/#{administration.to_param}/archive"
        expect(administration.reload).to_not be_active
      end
    end
  end

  context 'with an inactive administration' do
    let(:administration) { Factory(:administration, :site => current_site, :active => false) }

    describe '#unarchive' do
      it 'should unarchive the administration' do
        post "/en/administrations/#{administration.to_param}/unarchive"
        expect(administration.reload).to be_active
      end
    end
  end
end
