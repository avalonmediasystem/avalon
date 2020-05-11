# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'rails_helper'

RSpec.describe SupplementalFilesController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # SupplementalFile.
  let(:valid_create_attributes) {
    { file: uploaded_file, label: 'label' }
  }

  let(:invalid_create_attributes) {
    {}
  }

  let(:valid_update_attributes) { 
    { label: 'new label' }
  }

  let(:invalid_update_attributes) { 
    { file: uploaded_file }
  }

  let(:uploaded_file) { fixture_file_upload('/collection_poster.png', 'image/png') }
  let(:master_file) { FactoryBot.create(:master_file) }
  let(:supplemental_file) { FactoryBot.create(:supplemental_file) }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SupplementalFilesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe 'security' do
    context 'with unauthenticated user' do
      it "all routes should redirect to sign in" do
        expect(post :create, params: { master_file_id: master_file.id }).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
        expect(put :update, params: { master_file_id: master_file.id, id: supplemental_file.id }).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
        expect(delete :destroy, params: { master_file_id: master_file.id, id: supplemental_file.id }).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
        expect(get :show, params: { master_file_id: master_file.id, id: supplemental_file.id }).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
      end
    end
    context 'with end-user' do
      before do
        login_as :user
      end
      it "all routes should redirect to /" do
        expect(post :create, params: { master_file_id: master_file.id }).to redirect_to(root_path)
        expect(put :update, params: { master_file_id: master_file.id, id: supplemental_file.id }).to redirect_to(root_path)
        expect(delete :destroy, params: { master_file_id: master_file.id, id: supplemental_file.id }).to redirect_to(root_path)
        expect(get :show, params: { master_file_id: master_file.id, id: supplemental_file.id }).to redirect_to(root_path)
      end
    end
  end

  describe "GET #show" do
    let(:master_file) { FactoryBot.create(:master_file, media_object: public_media_object, supplemental_files: [supplemental_file]) }
    let(:public_media_object) { FactoryBot.create(:fully_searchable_media_object) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_attached_file) }

    it "returns the supplemental file content" do
      get :show, params: { master_file_id: master_file.id, id: supplemental_file.id }, session: valid_session
      expect(response).to redirect_to Rails.application.routes.url_helpers.rails_blob_path(supplemental_file.file, disposition: "attachment")
    end
  end

  describe "POST #create" do
    before do
      login_as :administrator
    end

    context 'json request' do
      context "with valid params" do
        it "updates the SupplementalFile" do
          expect {
            post :create, params: { master_file_id: master_file.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
          }.to change { master_file.reload.supplemental_files.size }.by(1)
          expect(response).to have_http_status(:created)
          expect(response.location).to eq master_file_supplemental_file_path(id: assigns(:supplemental_file).id, master_file_id: master_file.id)

          expect(master_file.supplemental_files.first.id).to eq 1
          expect(master_file.supplemental_files.first.label).to eq 'label'
          expect(master_file.supplemental_files.first.file).to be_attached
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          post :create, params: { master_file_id: master_file.id, supplemental_file: invalid_create_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(400)
        end
      end
    end

    context 'html request' do
      let(:media_object) { FactoryBot.create(:media_object) }
      let(:master_file) { FactoryBot.create(:master_file, media_object_id: media_object.id) }

      context "with valid params" do
        it "updates the SupplementalFile" do
          expect {
            post :create, params: { master_file_id: master_file.id, supplemental_file: valid_create_attributes, format: :html }, session: valid_session
          }.to change { master_file.reload.supplemental_files.size }.by(1)
          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:success]).to be_present

          expect(master_file.supplemental_files.first.id).to eq 1
          expect(master_file.supplemental_files.first.label).to eq 'label'
          expect(master_file.supplemental_files.first.file).to be_attached
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          post :create, params: { master_file_id: master_file.id, supplemental_file: invalid_create_attributes, format: :html }, session: valid_session
          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:error]).to be_present
        end
      end
    end

    context 'does not attach' do
      let(:supplemental_file) { FactoryBot.build(:supplemental_file) }
      before do
        allow(SupplementalFile).to receive(:new).and_return(supplemental_file)
        allow(supplemental_file).to receive(:attach_file).and_return(nil)
      end

      it 'does not create a SupplementalFile record' do
        expect {
          post :create, params: { master_file_id: master_file.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
        }.not_to change { SupplementalFile.count }#.and_not_to change { master_file.reload.supplemental_files.size }
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end

    context 'throws error while attaching' do
      let(:supplemental_file) { FactoryBot.build(:supplemental_file) }
      before do
        allow(SupplementalFile).to receive(:new).and_return(supplemental_file)
        allow(supplemental_file).to receive(:attach_file).and_raise("ERROR!!!!")
      end

      it 'does not create a SupplementalFile record' do
        expect {
          post :create, params: { master_file_id: master_file.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
        }.not_to change { SupplementalFile.count }#.and_not_to change { master_file.reload.supplemental_files.size }
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end
  end

  describe "PUT #update" do
    let(:master_file) { FactoryBot.create(:master_file, supplemental_files: [supplemental_file]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_attached_file, label: 'label') }

    before do
      login_as :administrator
    end

    context 'json request' do
      context "with valid params" do
        it "creates a new SupplementalFile" do
          expect {
            put :update, params: { master_file_id: master_file.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :json }, session: valid_session
          }.to change { master_file.reload.supplemental_files.first.label }.from('label').to('new label')

          expect(response).to have_http_status(:ok)
          expect(response.location).to eq master_file_supplemental_file_path(id: assigns(:supplemental_file).id, master_file_id: master_file.id)
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          put :update, params: { master_file_id: master_file.id, id: supplemental_file.id, supplemental_file: invalid_update_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(400)
        end
      end

      context "with missing id" do
        it "returns a 404" do
          put :update, params: { master_file_id: master_file.id, id: 'missing-id', supplemental_file: valid_update_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'html request' do
      let(:media_object) { FactoryBot.create(:media_object) }
      let(:master_file) { FactoryBot.create(:master_file, media_object_id: media_object.id, supplemental_files: [supplemental_file]) }

      context "with valid params" do
        it "creates a new SupplementalFile" do
          expect {
            put :update, params: { master_file_id: master_file.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
          }.to change { master_file.reload.supplemental_files.first.label }.from('label').to('new label')

          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:success]).to be_present
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          put :update, params: { master_file_id: master_file.id, id: supplemental_file.id, supplemental_file: invalid_update_attributes, format: :html }, session: valid_session
          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:error]).to be_present
        end
      end

      context "with missing id" do
        it "returns a 404" do
          put :update, params: { master_file_id: master_file.id, id: 'missing-id', supplemental_file: valid_update_attributes, format: :html }, session: valid_session
          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:error]).to be_present
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let(:master_file) { FactoryBot.create(:master_file, supplemental_files: [supplemental_file]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_attached_file) }

    before do
      login_as :administrator
    end

    context 'json request' do
      context "with valid params" do
        it "deletes the SupplementalFile" do
          expect {
            delete :destroy, params: { master_file_id: master_file.id, id: supplemental_file.id, format: :json }, session: valid_session
          }.to change { master_file.reload.supplemental_files.count }.by(-1)
          expect(response).to have_http_status(:no_content)
          # TODO: expect file contents to have been removed
        end
      end

      context "with missing id" do
        it "returns a 404" do
          delete :destroy, params: { master_file_id: master_file.id, id: 'missing-id', format: :json }, session: valid_session
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'html request' do
      let(:media_object) { FactoryBot.create(:media_object) }
      let(:master_file) { FactoryBot.create(:master_file, media_object_id: media_object.id, supplemental_files: [supplemental_file]) }
  
      context "with valid params" do
        it "deletes the SupplementalFile" do
          expect {
            delete :destroy, params: { master_file_id: master_file.id, id: supplemental_file.id, format: :html }, session: valid_session
          }.to change { master_file.reload.supplemental_files.count }.by(-1)
          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:success]).to be_present
          # TODO: expect file contents to have been removed
        end
      end
  
      context "with missing id" do
        it "returns a 404" do
          delete :destroy, params: { master_file_id: master_file.id, id: 'missing-id', format: :html }, session: valid_session
          expect(response).to redirect_to(edit_media_object_path(media_object.id, step: 'structure'))
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end