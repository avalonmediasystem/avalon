# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
#   spec

RSpec.shared_examples 'a nested controller for' do |object_class|

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

  let(:supplemental_file) { FactoryBot.create(:supplemental_file) }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SupplementalFilesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:class_name) { object_class.model_name.singular }
  let(:class_id) { "#{class_name}_id" }

  let(:media_object) { FactoryBot.create(:media_object, supplemental_files: [supplemental_file]) }
  let(:master_file) { FactoryBot.create(:master_file, media_object_id: media_object.id, supplemental_files: [supplemental_file]) }
  let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_attached_file, label: 'label') }
  let(:object) { object_class == MasterFile ? master_file : media_object }
  let(:manager) { media_object.collection.managers.first }

  describe 'security' do
    context 'with unauthenticated user' do
      it "all routes should return 401" do
        expect(post :create, params: { class_id => object.id }).to have_http_status(401)
        expect(put :update, params: { class_id =>  object.id, id: supplemental_file.id }).to have_http_status(401)
        expect(delete :destroy, params: { class_id =>  object.id, id: supplemental_file.id }).to have_http_status(401)
        expect(get :show, params: { class_id =>  object.id, id: supplemental_file.id }).to have_http_status(401)
      end
    end
    context 'with end-user without permission' do
      before do
        login_as :user
      end
      it "all routes should return 401" do
        expect(post :create, params: { class_id => object.id }).to have_http_status(401)
        expect(put :update, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
        expect(delete :destroy, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
        expect(get :show, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
      end
    end
  end

  describe "GET #show" do
    let(:master_file) { FactoryBot.create(:master_file, media_object: public_media_object, supplemental_files: [supplemental_file]) }
    let(:public_media_object) { FactoryBot.create(:fully_searchable_media_object, supplemental_files: [supplemental_file]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_attached_file) }
    let(:object) { object_class == MasterFile ? master_file : public_media_object }

    it "returns the supplemental file content" do
      get :show, params: { class_id => object.id, id: supplemental_file.id }, session: valid_session
      expect(response).to redirect_to Rails.application.routes.url_helpers.rails_blob_path(supplemental_file.file, disposition: "attachment")
    end
  end

  describe "POST #create" do
    let(:media_object) { FactoryBot.create(:media_object) }
    let(:master_file) { FactoryBot.create(:master_file, media_object_id: media_object.id) }
    let(:object) { object_class == MasterFile ? master_file : media_object }

    before do
      login_user manager
    end

    context 'json request' do
      context "with valid params" do
        it "updates the SupplementalFile for #{object_class}" do
          expect {
            post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to have_http_status(:created)
          expect(response.location).to eq "/#{object_class.model_name.plural}/#{object.id}/supplemental_files/#{assigns(:supplemental_file).id}"

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'label'
          expect(object.supplemental_files.first.file).to be_attached
        end

        let(:tags) { ["transcript"] }
        let(:uploaded_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.vtt'), 'text/vtt') }
        let(:valid_create_attributes_with_tags) { valid_create_attributes.merge(tags: tags) }
        it "creates a SupplementalFile with tags for #{object_class}" do
          expect {
            post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes_with_tags, format: :json }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to have_http_status(:created)
          expect(response.location).to eq "/#{object_class.model_name.plural}/#{object.id}/supplemental_files/#{assigns(:supplemental_file).id}"

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'label'
          expect(object.supplemental_files.first.tags).to eq tags
          expect(object.supplemental_files.first.file).to be_attached
        end

        context 'with mime type that does not match extension' do
          let(:tags) { ['caption'] }
          let(:extension) { 'srt' }
          let(:uploaded_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.srt'), 'text/plain') }
          it "creates a SupplementalFile with correct content_type" do
            expect{
              post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes_with_tags, format: :json}, session: valid_session
            }.to change { object.reload.supplemental_files.size }.by(1)
            expect(response).to have_http_status(:created)
            expect(response.location).to eq "/#{object_class.model_name.plural}/#{object.id}/supplemental_files/#{assigns(:supplemental_file).id}"

            expect(object.supplemental_files.first.id).to eq 1
            expect(object.supplemental_files.first.label).to eq 'label'
            expect(object.supplemental_files.first.tags).to eq tags
            expect(object.supplemental_files.first.file).to be_attached
            expect(object.supplemental_files.first.file.content_type).to eq Mime::Type.lookup_by_extension(extension)
          end
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          post :create, params: { class_id => object.id, supplemental_file: invalid_create_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(400)
        end
      end
    end

    context 'html request' do
      context "with valid params" do
        it "updates the SupplementalFile" do
          expect {
            post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes, format: :html }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:success]).to be_present

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'label'
          expect(object.supplemental_files.first.file).to be_attached
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          post :create, params: { class_id => object.id, supplemental_file: invalid_create_attributes, format: :html }, session: valid_session
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
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
          post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
        }.not_to change { SupplementalFile.count }#.and_not_to change { master_file.reload.supplemental_files.size }
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end

    context 'throws error while attaching' do
      let(:supplemental_file) { FactoryBot.build(:supplemental_file) }
      before do
        allow(SupplementalFile).to receive(:new).and_return(supplemental_file)
        allow(supplemental_file).to receive(:attach_file).and_raise(LoadError, "ERROR!!!!")
      end

      it 'does not create a SupplementalFile record' do
        expect {
          post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
        }.not_to change { SupplementalFile.count }#.and_not_to change { master_file.reload.supplemental_files.size }
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end
  end

  describe "PUT #update" do
    before do
      login_user manager
    end

    context 'json request' do
      context "with valid params" do
        it "creates a new SupplementalFile" do
          expect {
            put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :json }, session: valid_session
          }.to change { object.reload.supplemental_files.first.label }.from('label').to('new label')

          expect(response).to have_http_status(:ok)
          expect(response.location).to eq "/#{object_class.model_name.plural}/#{object.id}/supplemental_files/#{assigns(:supplemental_file).id}"
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: invalid_update_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(400)
        end
      end

      context "with missing id" do
        it "returns a 404" do
          put :update, params: { class_id => object.id, id: 'missing-id', supplemental_file: valid_update_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'html request' do
      context "with valid params" do
        it "creates a new SupplementalFile" do
          expect {
            put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
          }.to change { master_file.reload.supplemental_files.first.label }.from('label').to('new label')

          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:success]).to be_present
        end
      end

      context "machine generated transcript" do
        let(:machine_param) { "machine_generated_#{supplemental_file.id}".to_sym }
        context "missing machine_generated tag" do
          let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, :with_transcript_tag, label: 'label') }
          it "adds machine generated note to tags" do
            expect {
              put :update, params: { class_id => object.id, id: supplemental_file.id, machine_param => 1, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
            }.to change { master_file.reload.supplemental_files.first.tags }.from(['transcript']).to(['transcript', 'machine_generated'])
          end
        end
        context "with machine_generated tag" do
          let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['transcript', 'machine_generated'], label: 'label (machine generated)') }
          it "does not add more instances of machine generated note" do
            expect {
              put :update, params: { class_id => object.id, id: supplemental_file.id, machine_param => 1, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
            }.to not_change { master_file.reload.supplemental_files.first.tags }.from(['transcript', 'machine_generated'])
          end
        end
        context "removing machine_generated designation" do
          let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['transcript', 'machine_generated'], label: 'label (machine generated)') }
          it "removes machine generated note from label and tags" do
            expect {
              put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
            }.to change { master_file.reload.supplemental_files.first.tags }.from(['transcript', 'machine_generated']).to(['transcript'])
          end
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: invalid_update_attributes, format: :html }, session: valid_session
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:error]).to be_present
        end
      end

      context "with missing id" do
        it "returns a 404" do
          put :update, params: { class_id => object.id, id: 'missing-id', supplemental_file: valid_update_attributes, format: :html }, session: valid_session
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:error]).to be_present
        end
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      login_user manager
    end

    context 'json request' do
      context "with valid params" do
        it "deletes the SupplementalFile" do
          expect {
            delete :destroy, params: { class_id => object.id, id: supplemental_file.id, format: :json }, session: valid_session
          }.to change { object.reload.supplemental_files.count }.by(-1)
          expect(response).to have_http_status(:no_content)
          # TODO: expect file contents to have been removed
        end
      end

      context "with missing id" do
        it "returns a 404" do
          delete :destroy, params: { class_id => object.id, id: 'missing-id', format: :json }, session: valid_session
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'html request' do
      context "with valid params" do
        it "deletes the SupplementalFile" do
          expect {
            delete :destroy, params: { class_id => object.id, id: supplemental_file.id, format: :html }, session: valid_session
          }.to change { object.reload.supplemental_files.count }.by(-1)
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:success]).to be_present
          # TODO: expect file contents to have been removed
        end
      end

      context "with missing id" do
        it "returns a 404" do
          delete :destroy, params: { class_id => object.id, id: 'missing-id', format: :html }, session: valid_session
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
