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
    {}
  }

  let(:uploaded_file) { fixture_file_upload('/collection_poster.png', 'image/png') }

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
    describe 'ingest api' do
      it "all routes should return 401 when no token is present" do
        expect(get :index, params: { class_id => object.id, format: 'json' }).to have_http_status(401)
        expect(get :show, params: { class_id => object.id, id: supplemental_file.id, format: 'json' }).to have_http_status(401)
        expect(post :create, params: { class_id => object.id, format: 'json' }).to have_http_status(401)
        expect(put :update, params: { class_id => object.id, id: supplemental_file.id, format: 'json' }).to have_http_status(401)
        expect(delete :destroy, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
      end
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :index, params: { class_id => object.id, format: 'json' }).to have_http_status(403)
        expect(get :show, params: { class_id => object.id, id: supplemental_file.id, format: 'json' }).to have_http_status(403)
        expect(post :create, params: { class_id => object.id, format: 'json' }).to have_http_status(403)
        expect(put :update, params: { class_id => object.id, id: supplemental_file.id, format: 'json' }).to have_http_status(403)
        expect(delete :destroy, params: { class_id => object.id, id: supplemental_file.id, format: 'json' }).to have_http_status(403)
      end
    end
    describe 'normal auth' do
      context 'with unauthenticated user' do
        it "all routes should return 401" do
          expect(get :index, params: { class_id => object.id, format: 'json' }).to have_http_status(401)
          expect(get :show, params: { class_id =>  object.id, id: supplemental_file.id }).to have_http_status(401)
          expect(post :create, params: { class_id => object.id }).to have_http_status(401)
          expect(put :update, params: { class_id =>  object.id, id: supplemental_file.id }).to have_http_status(401)
          expect(delete :destroy, params: { class_id =>  object.id, id: supplemental_file.id }).to have_http_status(401)
        end
      end
      context 'with end-user without permission' do
        before do
          login_as :user
        end
        it "all routes should return 401" do
          expect(get :index, params: { class_id => object.id, format: 'json' }).to have_http_status(401)
          expect(get :show, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
          expect(post :create, params: { class_id => object.id }).to have_http_status(401)
          expect(put :update, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
          expect(delete :destroy, params: { class_id => object.id, id: supplemental_file.id }).to have_http_status(401)
        end
      end
    end
  end

  describe "GET #index" do
    subject { JSON.parse(response.body) }
    let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }
    let(:media_object) { FactoryBot.create(:fully_searchable_media_object) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_attached_file, parent_id: object.id) }
    let(:caption) { FactoryBot.create(:supplemental_file, :with_caption_file, tags: ['caption', 'transcript'], parent_id: object.id) }
    let(:transcript) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['transcript', 'machine_generated'], parent_id: object.id) }
    let(:object) { object_class == MasterFile ? master_file : media_object }

    before :each do
      login_user manager
      object.supplemental_files = [supplemental_file, caption, transcript]
      object.save
    end

    it "returns metadata for all associated supplemental files" do
      get :index, params: { class_id => object.id, format: 'json' }, session: valid_session
      expect(subject.count).to eq 3
      [supplemental_file, caption, transcript].each do |file|
        expect(subject.any? { |s| s == JSON.parse(file.as_json.to_json) }).to eq true
      end
    end

    it "paginates results when requested" do
      get :index, params: { class_id => object.id, format: 'json', per_page: 1, page: 1 }, session: valid_session
      expect(subject.count).to eq 1
      expect(subject.first.symbolize_keys).to eq supplemental_file.as_json
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

    context '.json' do
      it 'returns the supplemental file metadata' do
        get :show, params: { class_id => object.id, id: supplemental_file.id, format: 'json' }, session: valid_session
        expect(JSON.parse(response.body).symbolize_keys).to eq supplemental_file.as_json
      end
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
      let(:metadata) { { label: 'label', type: 'caption', language: 'French', machine_generated: true, treat_as_transcript: true } }
      context "with valid params" do
        let(:uploaded_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.vtt'), 'text/vtt') }
        let(:valid_create_attributes) { { file: uploaded_file, metadata: metadata.to_json } }
        it "creates a SupplementalFile for #{object_class}" do
          expect {
            post :create, params: { class_id => object.id, **valid_create_attributes, format: :json }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to eq ({ "id" => assigns(:supplemental_file).id })

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'label'
          expect(object.supplemental_files.first.file).to be_attached
        end

        context 'with just metadata' do
          it "creates a SupplementalFile for #{object_class}" do
            request.headers['Content-Type'] = 'application/json'
            expect {
              post :create, params: { class_id => object.id, metadata: metadata.to_json, format: :json }, session: valid_session
            }.to change { object.reload.supplemental_files.size }.by(1)
            expect(response).to have_http_status(:created)
            expect(JSON.parse(response.body)).to eq ({ "id" => assigns(:supplemental_file).id })

            expect(object.supplemental_files.first.id).to eq 1
            expect(object.supplemental_files.first.label).to eq 'label'
            expect(object.supplemental_files.first.language).to eq 'fre'
            expect(object.supplemental_files.first.tags).to match_array ['caption', 'transcript', 'machine_generated']
            expect(object.supplemental_files.first.file).to_not be_attached
          end

          context 'with just inlined metadata' do
            it "creates a SupplementalFile for #{object_class}" do
              request.headers['Content-Type'] = 'application/json'
              expect {
                post :create, params: { class_id => object.id, **metadata, format: :json }, session: valid_session
              }.to change { object.reload.supplemental_files.size }.by(1)
              expect(response).to have_http_status(:created)
              expect(JSON.parse(response.body)).to eq ({ "id" => assigns(:supplemental_file).id })

              expect(object.supplemental_files.first.id).to eq 1
              expect(object.supplemental_files.first.label).to eq 'label'
              expect(object.supplemental_files.first.language).to eq 'fre'
              expect(object.supplemental_files.first.tags).to match_array ['caption', 'transcript', 'machine_generated']
              expect(object.supplemental_files.first.file).to_not be_attached
            end
          end
        end

        context 'with incomplete metadata' do
          let(:metadata) { { label: 'label' } }
          it "creates a SupplementalFile for #{object_class} with default values" do
            request.headers['Content-Type'] = 'application/json'
            expect {
              post :create, params: { class_id => object.id, metadata: metadata.to_json, format: :json }, session: valid_session
            }.to change { object.reload.supplemental_files.size }.by(1)
            expect(response).to have_http_status(:created)
            expect(JSON.parse(response.body)).to eq ({ "id" => assigns(:supplemental_file).id })

            expect(object.supplemental_files.first.id).to eq 1
            expect(object.supplemental_files.first.label).to eq 'label'
            expect(object.supplemental_files.first.language).to eq 'eng'
            expect(object.supplemental_files.first.tags).to eq []
            expect(object.supplemental_files.first.file).to_not be_attached
          end
        end
      end

      context "with invalid params" do
        it "returns a 400" do
          post :create, params: { class_id => object.id, supplemental_file: invalid_create_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(400)
        end
      end

      context "with invalid file type" do
        it "returns a 500" do
          post :create, params: { class_id=> object.id, file: uploaded_file, type: 'caption', format: :json }, session: valid_session
          expect(response).to have_http_status(500)
        end
      end
    end

    context 'html request' do
      context "with valid params" do
        it "creates a SupplementalFile for #{object_class}" do
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

      context "including tags" do
        let(:tags) { ["transcript"] }
        let(:uploaded_file) { fixture_file_upload('/captions.vtt', 'text/vtt') }
        let(:valid_create_attributes_with_tags) { valid_create_attributes.merge(tags: tags) }

        it "creates a SupplementalFile with tags for #{object_class}" do
          expect {
            post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes_with_tags, format: :html }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:success]).to be_present

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'label'
          expect(object.supplemental_files.first.tags).to eq tags
          expect(object.supplemental_files.first.file).to be_attached
        end
      end

      context 'with mime type that does not match extension' do
        let(:tags) { ['caption'] }
        let(:extension) { 'srt' }
        let(:uploaded_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.srt'), 'text/plain') }
        let(:valid_create_attributes_with_tags) { valid_create_attributes.merge(tags: tags) }
        it "creates a SupplementalFile with correct content_type" do
          expect{
            post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes_with_tags, format: :html }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:success]).to be_present

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'label'
          expect(object.supplemental_files.first.tags).to eq tags
          expect(object.supplemental_files.first.file).to be_attached
          expect(object.supplemental_files.first.file.content_type).to eq Mime::Type.lookup_by_extension(extension)
        end
      end

      context 'API with just a file' do
        let(:uploaded_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.srt'), 'text/plain') }
        before { ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com' }
        it "creates a SupplementalFile for #{object_class}" do
          request.headers['Avalon-Api-Key'] = 'secret_token'
          request.headers['Accept'] = 'application/json'
          expect {
            post :create, params: { class_id => object.id, file: uploaded_file, format: :html }, session: valid_session
          }.to change { object.reload.supplemental_files.size }.by(1)
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to eq ({ "id" => assigns(:supplemental_file).id })

          expect(object.supplemental_files.first.id).to eq 1
          expect(object.supplemental_files.first.label).to eq 'captions.srt'
          expect(object.supplemental_files.first.language).to eq Settings.caption_default.language
          expect(object.supplemental_files.first.tags).to be_empty
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

    context 'fails to attach file' do
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

    context 'throws error while saving' do
      let(:supplemental_file) { FactoryBot.build(:supplemental_file) }
      before do
        allow(SupplementalFile).to receive(:new).and_return(supplemental_file)
        allow(master_file).to receive(:save).and_return(false)
        allow(controller).to receive(:fetch_object).and_return(master_file)
      end

      it 'does not add a SupplementalFile to parent object' do
        expect {
          post :create, params: { class_id => object.id, supplemental_file: valid_create_attributes, format: :json }, session: valid_session
        }.not_to change { master_file.reload.supplemental_files.size }
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
      before :each do
        request.headers['Content-Type'] = 'application/json'
      end
      context "with valid metadata params" do
        let(:valid_update_attributes) { { label: 'new label', type: 'transcript', machine_generated: true }.to_json }
        it "updates the SupplementalFile metadata for #{object_class}" do
          expect {
            put :update, params: { class_id => object.id, id: supplemental_file.id, metadata: valid_update_attributes, format: :json }, session: valid_session
          }.to change { object.reload.supplemental_files.first.label }.from('label').to('new label')
           .and change { object.reload.supplemental_files.first.tags }.from([]).to(['transcript', 'machine_generated'])

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({ "id": supplemental_file.id }.to_json)
        end
      end

      context "with new file and valid metadata params" do
        let(:file_update) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.vtt'), 'text/vtt') }
        it "returns a 400" do
          put :update, params: { class_id => object.id, id: supplemental_file.id, file: file_update, supplemental_file: valid_update_attributes, format: :json }, session: valid_session
          expect(response).to have_http_status(400)
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
        it "updates the SupplementalFile for #{object_class}" do
          expect {
            put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
          }.to change { master_file.reload.supplemental_files.first.label }.from('label').to('new label')

          expect(response).to redirect_to("http://#{@request.host}/media_objects/#{media_object.id}/edit?step=file-upload")
          expect(flash[:success]).to be_present
        end
      end

      context "machine generated file" do
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

      context "caption treated as transcript" do
        let(:transcript_param) { "treat_as_transcript_#{supplemental_file.id}".to_sym }
        context "missing transcript tag" do
          let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_caption_file, :with_caption_tag, label: 'label') }
          it "adds transcript note to tags" do
            expect {
              put :update, params: { class_id => object.id, id: supplemental_file.id, transcript_param => 1, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
            }.to change { master_file.reload.supplemental_files.first.tags }.from(['caption']).to(['caption', 'transcript'])
          end
        end
        context "with transcript tag" do
          let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['caption', 'transcript'], label: 'label') }
          it "does not add more instances of transcript note" do
            expect {
              put :update, params: { class_id => object.id, id: supplemental_file.id, transcript_param => 1, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
            }.to not_change { master_file.reload.supplemental_files.first.tags }.from(['caption', 'transcript'])
          end
        end
        context "removing transcript designation" do
          let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['caption', 'transcript'], label: 'label (machine generated)') }

          before do
            if object.is_a?(MasterFile)
              supplemental_file.parent_id = object.id
              supplemental_file.save
              mo = object.media_object
              mo.sections = [object]
              mo.save
            end
          end

          it "removes transcript note from tags" do
            expect {
              put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file: valid_update_attributes, format: :html }, session: valid_session
            }.to change { master_file.reload.supplemental_files.first.tags }.from(['caption', 'transcript']).to(['caption'])
          end

          it 'removes transcript from parent media object\'s index' do
            # Media object only looks at section files for has_transcript check,
            # so we only test against the MasterFile case.
            if object.is_a?(MasterFile)
              expect{
                put :update, params: { class_id => object.id, id: supplemental_file.id, supplemental_file:valid_update_attributes, format: :html}, session: valid_session
              }.to change { object.media_object.to_solr(include_child_fields: true)['has_transcripts_bsi'] }.from(true).to(false)
            end
          end
        end
      end

      context "API with new file" do
        let(:file_update) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'captions.vtt'), 'text/vtt') }
        before { ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com' }
        it "updates the SupplementalFile attached file for #{object_class}" do
          request.headers['Avalon-Api-Key'] = 'secret_token'
          request.headers['Accept'] = 'application/json'
          expect {
            put :update, params: { class_id => object.id, id: supplemental_file.id, file: file_update, format: :html }, session: valid_session
          }.to change { object.reload.supplemental_files.first.file }

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq({ "id": supplemental_file.id }.to_json)
        end
      end

      context "API without file" do
        before { ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com' }
        it "returns a 400" do
          request.headers['Avalon-Api-Key'] = 'secret_token'
          request.headers['Accept'] = 'application/json'
          put :update, params: { class_id=> object.id, id: supplemental_file.id, metadata: valid_update_attributes, format: :html }, session: valid_session
          expect(response).to have_http_status(400)
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

      context "API updating caption with invalid file type" do
        let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_caption_tag) }
        before { ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com' }
        it "returns a 500" do
          request.headers['Avalon-Api-Key'] = 'secret_token'
          request.headers['Accept'] = 'application/json'
          put :update, params: { class_id=> object.id, id: supplemental_file.id, file: uploaded_file, format: :html }, session: valid_session
          expect(response).to have_http_status(500)
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

    context 'throws error while saving' do
      let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
      before do
        allow(master_file).to receive(:save).and_return(false)
        allow(controller).to receive(:fetch_object).and_return(master_file)
      end

      it 'returns a 500' do
        delete :destroy, params: { class_id => object.id, id: supplemental_file.id, format: :json }, session: valid_session
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["errors"]).to be_present
      end
    end

    context 'supplemental file marked as transcript' do
      let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['caption', 'transcript']) }

      before do
        if object.is_a?(MasterFile)
          supplemental_file.parent_id = object.id
          supplemental_file.save
          mo = object.media_object
          mo.sections = [object]
          mo.save
        end
      end

      it 'removes transcript from parent media object\'s index' do
        # Media object only looks at section files for has_transcript check,
        # so we only test against the MasterFile case.
        if object.is_a?(MasterFile)
          expect{
            delete :destroy, params: { class_id => object.id, id: supplemental_file.id, format: :html}, session: valid_session
          }.to change { object.media_object.to_solr(include_child_fields: true)['has_transcripts_bsi'] }.from(true).to(false)
        end
      end
    end
  end
end
