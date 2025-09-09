# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

describe MediaObjectsController, type: :controller do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  render_views

  before(:each) do
    request.env["HTTP_REFERER"] = '/'
  end

  describe 'security' do
    let(:media_object) { FactoryBot.create(:media_object) }
    let(:published_media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
    let(:private_media_object) { FactoryBot.create(:published_media_object, visibility: 'private') }
    describe 'ingest api' do
      before do
        ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
      end
      it "most routes should return 401 when no token is present" do
        expect(get :index, format: 'json').to have_http_status(401)
        expect(post :create, format: 'json').to have_http_status(401)
        expect(put :update, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
        expect(put :json_update, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
      end
      describe '#show' do
        it "returns 401 when no token is present, and unpublished" do
          expect(get :show, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
        end
        it "returns 401 for published private items when no token is present" do
          expect(get :show, params: { id: private_media_object.id, format: 'json' }).to have_http_status(401)
        end
        it "permits published public items when no token is present" do
          expect(get :show, params: { id: published_media_object.id, format: 'json' }).to have_http_status(200)
        end
      end
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :index, format: 'json').to have_http_status(403)
        expect(get :show, params: { id: media_object.id, format: 'json' }).to have_http_status(403)
        expect(post :create, format: 'json').to have_http_status(403)
        expect(put :update, params: { id: media_object.id, format: 'json' }).to have_http_status(403)
        expect(put :json_update, params: { id: media_object.id, format: 'json' }).to have_http_status(403)
      end
    end
    describe 'normal auth' do
      context 'with unauthenticated user' do
        # New is isolated here due to issues caused by the controller instance not being regenerated
        it "should redirect to sign in" do
          expect(get :new).to render_template('errors/restricted_pid')
        end
        # Item page is isolated since it does not require user authentication before action
        it "item page should redirect to restricted content page" do
          expect(get :show, params: { id: media_object.id }).to render_template('errors/restricted_pid')
        end
        it "all routes should redirect to sign in" do
          expect(get :edit, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :confirm_remove, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(put :update, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(put :update_status, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :tree, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :deliver_content, params: { id: media_object.id, file: 'descMetadata' }).to render_template('errors/restricted_pid')
          expect(delete :destroy, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(post :add_to_playlist, params: { id: media_object.id, post: {} }).to render_template('errors/restricted_pid')
        end
        it "json routes should return 401" do
          expect(post :create, format: 'json').to have_http_status(401)
          expect(put :json_update, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
          expect(get :show_progress, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
        end
      end
      context 'with end-user' do
        before do
          login_as :user
        end
        # New is isolated here due to issues caused by the controller instance not being regenerated
        it "should redirect to restricted content page" do
          expect(get :new).to render_template('errors/restricted_pid')
        end
        it "media object destroy and update_status should redirect to /" do
          expect(put :update_status, params: { id: media_object.id }).to redirect_to(root_path)
          expect(delete :destroy, params: { id: media_object.id }).to redirect_to(root_path)
        end
        it "all routes should redirect to restricted content page" do
          expect(get :show, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :edit, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :confirm_remove, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(put :update, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :tree, params: { id: media_object.id }).to render_template('errors/restricted_pid')
          expect(get :deliver_content, params: { id: media_object.id, file: 'descMetadata' }).to render_template('errors/restricted_pid')
          expect(post :add_to_playlist, params: { id: media_object.id, post: { masterfile_id: nil } }).to render_template('errors/restricted_pid')
        end
        it "json routes should return 401" do
          expect(post :create, format: 'json').to have_http_status(401)
          expect(put :json_update, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
          expect(get :show_progress, params: { id: media_object.id, format: 'json' }).to have_http_status(401)
        end
      end
    end
  end

  context 'Avalon Intercom methods' do
    let!(:target_collections) { [{'id' => 'abc123', 'name' => 'Test Collection'}] }
    before :all do
      Settings.intercom = {
        'default' => {
          'url' => 'https://target.avalon.com/',
          'api_token' => 'a_valid_token',
          'import_bib_record' => true,
          'publish' => false,
          'push_label' => 'Push to Target'
        }
      }
    end
    after :all do
      Settings.intercom = nil
    end

    describe '#intercom_collections' do
      before do
        login_as :user
        allow_any_instance_of(Avalon::Intercom).to receive(:user_collections).and_return target_collections
      end
      it 'should return collections as json from target' do
        get 'intercom_collections', format: 'json'
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq([{'id'=>'abc123', 'name'=>'Test Collection', 'default'=>false}])
        expect(session['intercom_collections']).to eq(target_collections)
        expect(session['intercom_default_collection']).to be nil
      end
      it 'should return collections with default set from session' do
        session[:intercom_default_collection] = 'abc123'
        get 'intercom_collections', format: 'json'
        expect(JSON.parse(response.body)).to eq([{'id'=>'abc123', 'name'=>'Test Collection', 'default'=>true}])
      end
    end

    describe '#intercom_push' do
      let(:media_object) { FactoryBot.create(:media_object) }
      let(:master_file_with_structure) { FactoryBot.create(:master_file, :with_structure, media_object: media_object) }
      let(:target_link) { { link: 'http://link.to/media_object' } }
      let(:error_status) { { message: 'Not authorized', status: 401 } }
      let(:media_object_permission) { 'You do not have permission to push this media object.' }
      let(:collection_permission) { 'You are not authorized to push to this collection.' }
      before do
        login_as(:administrator)
        session[:intercom_collections] = {}
        session[:intercom_default_collection] = ''
        media_object.sections = [master_file_with_structure]
        allow_any_instance_of(Avalon::Intercom).to receive(:fetch_user_collections).and_return target_collections
      end
      it 'should refetch user collections from target and set session' do
        allow_any_instance_of(Avalon::Intercom).to receive(:push_media_object).and_return target_link
        expect_any_instance_of(Avalon::Intercom).to receive(:fetch_user_collections).once
        patch :intercom_push, params: { id: media_object.id, collection_id: target_collections.first['id'] }
        expect(session[:intercom_collections]).to eq(target_collections)
        expect(session[:intercom_default_collection]).to eq(target_collections.first['id'])
      end
      it 'should return error message' do
        allow_any_instance_of(Avalon::Intercom).to receive(:push_media_object).and_return error_status
        patch :intercom_push, params: { id: media_object.id, collection_id: target_collections.first['id'] }
        expect(flash[:alert]).to eq('There was an error pushing the item. (401: Not authorized)')
      end
      it 'should return no permission for item' do
        allow_any_instance_of(Avalon::Intercom).to receive(:push_media_object).and_return({ message: media_object_permission })
        patch :intercom_push, params: { id: media_object.id, collection_id: target_collections.first['id'] }
        expect(flash[:alert]).to eq(media_object_permission)
      end
      it 'should return no permission for collection' do
        allow_any_instance_of(Avalon::Intercom).to receive(:push_media_object).and_return({ message: collection_permission })
        patch :intercom_push, params: { id: media_object.id, collection_id: target_collections.first['id'] }
        expect(flash[:alert]).to eq(collection_permission)
      end
    end
  end

  context "JSON API methods" do
    let!(:collection) { FactoryBot.create(:collection) }
    let!(:testdir) {'spec/fixtures/'}
    let!(:filename) {'videoshort.high.mp4'}
    let!(:absolute_location) {Rails.root.join(File.join(testdir, filename)).to_s}
    let!(:structure) {File.read(File.join(testdir, 'structure.xml'))}
    let!(:captions) {File.read(File.join(testdir, 'sheephead_mountain.mov.vtt'))}
    let!(:bib_id) { '7763100' }
    let!(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
    let!(:sru_response) { File.read(File.expand_path("../../fixtures/#{bib_id}.xml",__FILE__)) }
    let!(:master_file) {{
        file_location: absolute_location,
        title: "Part 1",
        files: [{
                  label: 'quality-high',
                  track_id: 'track-1',
                  url: absolute_location,
                  duration: "6315",
                  mime_type:  "video/mp4",
                  audio_bitrate: "127716.0",
                  audio_codec: "AAC",
                  video_bitrate: "1000000.0",
                  video_codec: "AVC",
                  width: "640",
                  height: "480"
                },
                {
                  label: 'quality-medium',
                  track_id: 'track-2',
                  url: absolute_location,
                  duration: "6315",
                  mime_type: "video/mp4",
                  audio_bitrate: "127716.0",
                  audio_codec: "AAC",
                  video_bitrate: "1000000.0",
                  video_codec: "AVC",
                  width: "640",
                  height: "480"
                }],
        file_checksum: "7ae24368ccb7a6c6422a14ff73f33c9a",
        file_size: "199160",
        duration: "6315",
        display_aspect_ratio: "1.7777777777777777",
        original_frame_size: "640x480",
        file_format: "Moving image",
        poster_offset: "0:02",
        thumbnail_offset: "0:02",
        date_digitized: "2015-12-31",
        workflow_name: "avalon",
        workflow_id: '1',
        # percent_complete: "100.0",
        # percent_succeeded: "100.0",
        # percent_failed: "0",
        # status_code: "COMPLETED",
        other_identifier: '40000000045312',
        structure: structure,
        captions: captions,
        captions_type: 'text/vtt'
      }}
    let!(:descMetadata_fields) {[
      :title,
      :alternative_title,
      :translated_title,
      :uniform_title,
      :statement_of_responsibility,
      :creator,
      :date_created,
      :date_issued,
      :copyright_date,
      :abstract,
      :note,
      :format,
      :resource_type,
      :contributor,
      :publisher,
      :genre,
      :subject,
      :related_item_url,
      :geographic_subject,
      :temporal_subject,
      :topical_subject,
      :bibliographic_id,
      :language,
      :terms_of_use,
      :table_of_contents,
      :physical_description,
      :other_identifier,
      :rights_statement,
      :series
    ]}

    describe "#create" do
      context 'using api' do
        let(:administrator) { FactoryBot.create(:administrator) }

        before(:each) do
          ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
          request.headers['Avalon-Api-Key'] = 'secret_token'
          allow_any_instance_of(MasterFile).to receive(:get_ffmpeg_frame_data).and_return('some data')
        end
        it "should respond with 422 if collection not found" do
          post 'create', params: { format: 'json', collection_id: "doesnt_exist" }
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)["errors"].class).to eq Array
          expect(JSON.parse(response.body)["errors"].first.class).to eq String
        end
        it "should respond with 422 if collection param not present" do
          post 'create', params: { format: 'json' }
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)["errors"].class).to eq Array
          expect(JSON.parse(response.body)["errors"].first.class).to eq String
        end
        it "should create a new media_object" do
          # master_file_obj = FactoryBot.create(:master_file, master_file.slice(:files))
          media_object = FactoryBot.create(:media_object)#, sections: [master_file_obj])
          fields = {other_identifier_type: []}
          descMetadata_fields.each {|f| fields[f] = media_object.send(f) }
          # fields = media_object.attributes.select {|k,v| descMetadata_fields.include? k.to_sym }
          post 'create', params: { format: 'json', fields: fields, files: [master_file], collection_id: collection.id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.title).to eq media_object.title
          expect(new_media_object.creator).to eq media_object.creator
          expect(new_media_object.date_issued).to eq media_object.date_issued
          expect(new_media_object.section_ids.size).to eq 1
          expect(new_media_object.duration).to eq '6315'
          expect(new_media_object.format).to eq ['video/mp4']
          expect(new_media_object.avalon_resource_type).to eq ['moving image']
          expect(new_media_object.sections.first.date_digitized).to eq('2015-12-31T00:00:00Z')
          expect(new_media_object.sections.first.identifier).to include('40000000045312')
          expect(new_media_object.sections.first.structuralMetadata.has_content?).to be_truthy
          expect(new_media_object.sections.first.captions.has_content?).to be_truthy
          expect(new_media_object.sections.first.captions.mime_type).to eq('text/vtt')
          expect(new_media_object.sections.first.derivatives.count).to eq(2)
          expect(new_media_object.sections.first.derivatives.first.location_url).to eq(absolute_location)
          expect(new_media_object.workflow.last_completed_step).to eq([HYDRANT_STEPS.last.step])
        end
        it "should create a new published media_object" do
          media_object = FactoryBot.create(:published_media_object)
          fields = {}
          descMetadata_fields.each {|f| fields[f] = media_object.send(f) }
          # fields = media_object.attributes.select {|k,v| descMetadata_fields.include? k.to_sym }
          post 'create', params: { format: 'json', fields: fields, files: [master_file], collection_id: collection.id, publish: true }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.published?).to be_truthy
          expect(new_media_object.workflow.last_completed_step).to eq([HYDRANT_STEPS.last.step])
        end
        it "should create a new media_object with successful bib import" do
          stub_request(:get, sru_url).to_return(body: sru_response)
          fields = { bibliographic_id: bib_id }
          post 'create', params: { format: 'json', import_bib_record: true, fields: fields, files: [master_file], collection_id: collection.id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.bibliographic_id).to eq({source: "local", id: bib_id})
          expect(new_media_object.title).to eq('245 A : B F G K N P S')
        end
        it "should create a new media_object with supplied fields when bib import fails" do
          stub_request(:get, sru_url).to_return(body: nil)
          ex_media_object = FactoryBot.create(:media_object)
          fields = {}
          descMetadata_fields.each {|f| fields[f] = ex_media_object.send(f) }
          fields[:bibliographic_id] = bib_id
          post 'create', params: { format: 'json', import_bib_record: true, fields: fields, files: [master_file], collection_id: collection.id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.bibliographic_id).to eq({source: "local", id: bib_id})
          expect(new_media_object.title).to eq ex_media_object.title
          expect(new_media_object.creator).to eq [] #creator no longer required, so supplied value won't be used
          expect(new_media_object.date_issued).to eq nil #date_issued no longer required, so supplied value won't be used
        end
        it "should create a new media_object, removing invalid data for non-required fields" do
          media_object = FactoryBot.create(:media_object)
          fields = {}
          descMetadata_fields.each {|f| fields[f] = media_object.send(f) }
          fields[:language] = ['???']
          fields[:related_item_url] = ['???']
          fields[:related_item_label] = ['???']
          fields[:note] = ['note']
          fields[:note_type] = ['???']
          fields[:date_created] = '???'
          fields[:copyright_date] = '???'
          fields[:rights_statement] = '???'
          post 'create', params: { format: 'json', fields: fields, files: [master_file], collection_id: collection.id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.title).to eq media_object.title
          expect(new_media_object.language).to eq []
          expect(new_media_object.related_item_url).to eq []
          expect(new_media_object.note).to eq []
          expect(new_media_object.date_created).to eq nil
          expect(new_media_object.copyright_date).to eq nil
          expect(new_media_object.rights_statement).to eq nil
        end
        it "should merge supplied other identifiers after bib import" do
          stub_request(:get, sru_url).to_return(body: sru_response)
          fields = { bibliographic_id: bib_id, other_identifier_type: ['other'], other_identifier: ['12345'] }
          post 'create', params: { format: 'json', import_bib_record: true, fields: fields, files: [master_file], collection_id: collection.id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.bibliographic_id).to eq({source: "local", id: bib_id})
          expect(new_media_object.other_identifier.find {|id_pair| id_pair[:source] == 'other'}).not_to be nil
          expect(new_media_object.other_identifier.find {|id_pair| id_pair[:source] == 'other'}[:id]).to eq('12345')
        end
        it "should merge supplied DC identifiers after bib import" do
          stub_request(:get, sru_url).to_return(body: sru_response)
          fields = { bibliographic_id: bib_id, identifier: ['ABC1234'] }
          post 'create', params: { format: 'json', import_bib_record: true, fields: fields, files: [master_file], collection_id: collection.id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.identifier).to eq(['ABC1234'])
        end
        it "should create a new media_object using ingest_api_hash of existing media_object" do
          # master_file_obj = FactoryBot.create(:master_file, master_file.slice(:files))
          media_object = FactoryBot.create(:fully_searchable_media_object, :with_completed_workflow)
          master_file = FactoryBot.create(:master_file, :with_derivative, :with_thumbnail, :with_poster, :with_structure, :with_captions, :with_comments, media_object: media_object)
          media_object.reload
          allow_any_instance_of(MasterFile).to receive(:extract_frame).and_return('some data')
          media_object.update_dependent_properties!
          api_hash = media_object.to_ingest_api_hash
          post 'create', params: { format: 'json', fields: api_hash[:fields], files: api_hash[:files], collection_id: media_object.collection_id }
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.title).to eq media_object.title
          expect(new_media_object.creator).to eq media_object.creator
          expect(new_media_object.date_issued).to eq media_object.date_issued
          expect(new_media_object.section_ids.size).to eq 1
          expect(new_media_object.duration).to eq media_object.duration
          expect(new_media_object.format).to eq media_object.format
          expect(new_media_object.note).to eq media_object.note
          expect(new_media_object.language).to eq media_object.language
          expect(new_media_object.all_comments).to eq media_object.all_comments
          expect(new_media_object.bibliographic_id).to eq media_object.bibliographic_id
          expect(new_media_object.related_item_url).to eq media_object.related_item_url
          expect(new_media_object.other_identifier).to eq media_object.other_identifier
          expect(new_media_object.rights_statement).to eq media_object.rights_statement
          expect(new_media_object.series).to eq media_object.series
          expect(new_media_object.avalon_resource_type).to eq media_object.avalon_resource_type
          expect(new_media_object.sections.first.date_digitized).to eq(media_object.sections.first.date_digitized)
          expect(new_media_object.sections.first.identifier).to eq(media_object.sections.first.identifier)
          expect(new_media_object.sections.first.structuralMetadata.has_content?).to be_truthy
          expect(new_media_object.sections.first.captions.has_content?).to be_truthy
          expect(new_media_object.sections.first.captions.mime_type).to eq(media_object.sections.first.captions.mime_type)
          expect(new_media_object.sections.first.derivatives.count).to eq(media_object.sections.first.derivatives.count)
          expect(new_media_object.sections.first.derivatives.first.location_url).to eq(media_object.sections.first.derivatives.first.location_url)
          expect(new_media_object.workflow.last_completed_step).to eq(media_object.workflow.last_completed_step)
        end
        it "should return 422 if master_file update failed" do
          media_object = FactoryBot.create(:published_media_object)
          fields = {}
          descMetadata_fields.each {|f| fields[f] = media_object.send(f) }
          allow_any_instance_of(MasterFile).to receive(:save).and_return false
          allow_any_instance_of(MasterFile).to receive(:stop_processing!)
          expect_any_instance_of(MediaObject).to receive(:destroy).once
          post 'create', params: { format: 'json', fields: fields, files: [master_file], collection_id: collection.id, publish: true }
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)["errors"].class).to eq Array
          expect(JSON.parse(response.body)["errors"].first.class).to eq String
        end
      end
    end
    describe "#update" do
      context 'using api' do
        let(:user) { FactoryBot.create(:administrator) }
        let(:media_object) { FactoryBot.create(:media_object, :with_master_file) }

        before(:each) do
          ApiToken.create token: 'secret_token', username: user.username, email: user.email
          request.headers['Avalon-Api-Key'] = 'secret_token'
          allow_any_instance_of(MasterFile).to receive(:get_ffmpeg_frame_data).and_return('some data')
        end

        it "should route json format to #json_update" do
          assert_routing({ path: 'media_objects/1.json', method: :put },
             { controller: 'media_objects', action: 'json_update', id: '1', format: 'json' })
        end
        it "should route unspecified format to #update" do
          assert_routing({ path: 'media_objects/1', method: :put },
             { controller: 'media_objects', action: 'update', id: '1', format: 'html' })
        end
        it "should update a media_object's metadata" do
          old_title = media_object.title
          put 'json_update', params: { format: 'json', id: media_object.id, fields: {title: old_title+'new'}, collection_id: media_object.collection_id }
          expect(JSON.parse(response.body)['id'].class).to eq String
          expect(JSON.parse(response.body)).not_to include('errors')
          media_object.reload
          expect(media_object.title).to eq old_title+'new'
        end
        it "should add a master_file to a media_object" do
          put 'json_update', params: { format: 'json', id: media_object.id, files: [master_file], collection_id: media_object.collection_id }
          expect(JSON.parse(response.body)['id'].class).to eq String
          expect(JSON.parse(response.body)).not_to include('errors')
          media_object.reload
          expect(media_object.sections.to_a.size).to eq 2
        end
        it "should update the poster and thumbnail for its masterfile" do
          media_object = FactoryBot.create(:media_object)
          put 'json_update', params: { format: 'json', id: media_object.id, files: [master_file], collection_id: media_object.collection_id }
          media_object.reload
          expect(media_object.sections.to_a.size).to eq 1
          expect(ExtractStillJob).to have_been_enqueued.with(media_object.sections.first.id, { type: 'both', offset: 2000, headers: nil })
        end
        it "should update the waveform for its masterfile" do
          media_object = FactoryBot.create(:media_object)
          put 'json_update', params: { format: 'json', id: media_object.id, files: [master_file], collection_id: media_object.collection_id }
          media_object.reload
          expect(media_object.sections.to_a.size).to eq 1
          expect(WaveformJob).to have_been_enqueued.with(media_object.sections.first.id)
        end
        it "should delete existing sections and add a new master_file to a media_object" do
          allow_any_instance_of(MasterFile).to receive(:stop_processing!)
          put 'json_update', params: { format: 'json', id: media_object.id, files: [master_file], collection_id: media_object.collection_id, replace_masterfiles: true }
          expect(JSON.parse(response.body)['id'].class).to eq String
          expect(JSON.parse(response.body)).not_to include('errors')
          media_object.reload
          expect(media_object.sections.to_a.size).to eq 1
        end
        it "should return 404 if media object doesn't exist" do
          allow_any_instance_of(MediaObject).to receive(:save).and_return false
          put 'json_update', params: { format: 'json', id: 'doesnt_exist', fields: {}, collection_id: media_object.collection_id }
          expect(response.status).to eq(404)
        end
        it "should return 422 if media object update failed" do
          allow_any_instance_of(MediaObject).to receive(:save).and_return false
          allow_any_instance_of(MasterFile).to receive(:stop_processing!)
          put 'json_update', params: { format: 'json', id: media_object.id, fields: {}, collection_id: media_object.collection_id }
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)["errors"].class).to eq Array
          expect(JSON.parse(response.body)["errors"].first.class).to eq String
        end

        context "as an authorized non-admin user" do
          let(:user) { FactoryBot.create(:manager) }
          let(:collection) { FactoryBot.create(:collection, managers: [user.username]) }
          let(:media_object) { FactoryBot.create(:media_object, collection: collection) }

          it "updates metadata" do
	    old_title = media_object.title
	    put 'json_update', params: { format: 'json', id: media_object.id, fields: {title: old_title+'new'}, collection_id: media_object.collection_id }
	    expect(JSON.parse(response.body)['id'].class).to eq String
	    expect(JSON.parse(response.body)).not_to include('errors')
	    media_object.reload
	    expect(media_object.title).to eq old_title+'new'
          end
        end

        context "collection_id parameter" do
          it "updates metadata without collection_id" do
	    old_title = media_object.title
	    put 'json_update', params: { format: 'json', id: media_object.id, fields: {title: old_title+'new'} }
	    expect(JSON.parse(response.body)['id'].class).to eq String
	    expect(JSON.parse(response.body)).not_to include('errors')
	    media_object.reload
	    expect(media_object.title).to eq old_title+'new'
          end
	  it "should respond with 422 if collection not found" do
	    put 'json_update', params: { format: 'json', id: media_object.id, collection_id: "doesnt_exist" }
	    expect(response.status).to eq(422)
	    expect(JSON.parse(response.body)).to include('errors')
	    expect(JSON.parse(response.body)["errors"].class).to eq Array
	    expect(JSON.parse(response.body)["errors"].first.class).to eq String
	  end
        end
      end
    end
  end

  describe "#new" do
    let!(:collection) { FactoryBot.create(:collection) }

    it "should not let manager of other collections create an item in this collection" do
      skip
    end

    context "Default permissions should be applied" do
      it "should be editable by the creator" do
        login_user collection.managers.first
        expect { get 'new', params: { collection_id: collection.id } }.to change { MediaObject.count }
        id = MediaObject.all.last.id
        expect(response).to redirect_to(edit_media_object_path(id: id))
      end

      it "should copy default permissions from its owning collection" do
        login_user collection.depositors.first

        get 'new', params: { collection_id: collection.id }

        #MediaObject.all.last.edit_users.should include(collection.managers)
        #MediaObject.all.last.edit_users.should include(collection.depositors)
      end
    end

  end

  describe "#edit" do
    let!(:media_object) { FactoryBot.create(:media_object) }

    it "should redirect to first workflow step if authorized to edit" do
       login_user media_object.collection.managers.first

       get 'edit', params: { id: media_object.id }
       expect(response).to be_successful
       expect(response).to render_template "_#{HYDRANT_STEPS.first.template}"
     end

    it "should not default to the Access Control page" do
      skip "[VOV-1165] Wait for product owner feedback on which step to default to"
    end

    context "Updating the metadata should result in valid input" do
      it "should ignore the PID if provided as a parameter"
      it "should ignore invalid attributes"
      it "should be able to retrieve an existing record from Fedora" do
        media_object.workflow.last_completed_step = 'resource-description'
        media_object.save

        # Set the task so that it can get to the resource-description step
        login_user media_object.collection.managers.first
        get :edit, params: { id: media_object.id, step: 'resource-description' }
        expect(response.response_code).to eq(200)
      end
      it "does not persist invalid media object after resource-description step" do
        media_object.workflow.last_completed_step = 'resource-description'
        media_object.save
        login_user media_object.collection.managers.first

        put :update, params: { id: media_object.id, step: 'resource-description', media_object: {title: ''} }
        expect(response.response_code).to eq(200)
        expect(flash[:error]).not_to be_empty
        media_object.reload
        expect(media_object.valid?).to be_truthy
        expect(media_object.title).not_to be_blank
      end
    end

    context "Persisting Permalinks" do
      before(:each) { login_user mo.collection.managers.first }
      context "Persisting Permalinks on unpublished media_object" do
        subject(:mo) { media_object }
        it "should persist new permalink on unpublished media_object" do
          expect { put 'update', params: { id: mo.id, step: 'resource-description', media_object: { permalink: 'newpermalink', title: 'newtitle',
                                   creator: 'newcreator', date_issued: 'newdateissued' } }}
            .to change { MediaObject.find(mo.id).permalink }
            .to('newpermalink')
        end
        it "should persist new permalink on unpublished media_object part" do
          part1 = FactoryBot.create(:master_file, media_object: mo)
          expect {put 'update', params: { id: mo.id, step: 'file-upload', master_files: { part1.id => { permalink: 'newpermalinkpart' }} }}
            .to change { MasterFile.find(part1.id).permalink }
            .to('newpermalinkpart')
        end
      end
      context "Persisting Permalinks on published media_object" do
        subject(:mo) { FactoryBot.create(:published_media_object, permalink: 'oldpermalink') }
        it "should persist updated permalink on published media_object" do
          expect { put 'update', params: { id: mo.id, step: 'resource-description', media_object: { permalink: 'newpermalink', title: mo.title,
                                   creator: mo.creator, date_issued: mo.date_issued } }}
            .to change { MediaObject.find(mo.id).permalink }
            .to('newpermalink')
        end
        it "should persist updated permalink on published media_object part" do
          part1 = FactoryBot.create(:master_file, permalink: 'oldpermalinkpart1', media_object: mo)
          expect { put 'update', params: { id: mo.id, step: 'file-upload', master_files: { part1.id => { permalink: 'newpermalinkpart' }} }}
            .to change { MasterFile.find(part1.id).permalink }
            .to('newpermalinkpart')
        end
      end
    end

    context "Hidden Items" do
      subject(:mo) { FactoryBot.create(:media_object, :with_completed_workflow, hidden: true) }
      let!(:user) { Faker::Internet.email }
      before(:each) { login_user mo.collection.managers.first }

      it "should retain the hidden status of an object when other access control settings change" do
        expect { put 'update', params: { id: mo.id, step: 'access-control', donot_advance: 'true', add_user: user, add_user_display: user, submit_add_user: 'Add' } }
          .not_to change { MediaObject.find(mo.id).hidden? }
      end
    end
  end

  describe "#index" do
    let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
    let!(:private_media_object) { FactoryBot.create(:published_media_object, visibility: 'private') }
    subject(:json) { JSON.parse(response.body) }

    context 'as an administrator' do
      let(:administrator) { FactoryBot.create(:administrator) }

      before(:each) do
        ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
        request.headers['Avalon-Api-Key'] = 'secret_token'
      end

      it "should return list of media_objects" do
        get 'index', format:'json'
        expect(json.count).to eq(2)
        expect(json.first['id']).to eq(media_object.id)
        expect(json.first['title']).to eq(media_object.title)
        expect(json.first['collection']).to eq(media_object.collection.name)
        expect(json.first['main_contributors']).to eq(media_object.creator)
        expect(json.first['publication_date']).to eq(media_object.date_created)
        expect(json.first['published_by']).to eq(media_object.avalon_publisher)
        expect(json.first['published']).to eq(media_object.published?)
        expect(json.first['summary']).to eq(media_object.abstract)
        expect(json.second['id']).to eq(private_media_object.id)
        expect(json.second['title']).to eq(private_media_object.title)
        expect(json.second['collection']).to eq(private_media_object.collection.name)
        expect(json.second['main_contributors']).to eq(private_media_object.creator)
        expect(json.second['publication_date']).to eq(private_media_object.date_created)
        expect(json.second['published_by']).to eq(private_media_object.avalon_publisher)
        expect(json.second['published']).to eq(private_media_object.published?)
        expect(json.second['summary']).to eq(private_media_object.abstract)
      end

      context "with structure" do
        let!(:master_file) { FactoryBot.create(:master_file, :with_structure, media_object: media_object) }
        it "should not return structure by default" do
          get 'index', params: {  format: 'json' }
          expect(json.first["files"][0]["structure"]).to be_blank
        end
        it "should return structure if requested" do
          get 'index', params: { format: 'json', include_structure: true }
          expect(json.first["files"][0]["structure"]).to eq master_file.structuralMetadata.content
        end
        it "should not return structure if requested" do
          get 'index', params: { format: 'json', include_structure: false}
          expect(json.first["files"][0]["structure"]).not_to eq master_file.structuralMetadata.content
        end
      end
    end

    context 'user is not an administrator' do
      let(:user) { FactoryBot.create(:user) }

      before(:each) do
        ApiToken.create token: 'user_token', username: user.username, email: user.email
        request.headers['Avalon-Api-Key'] = 'user_token'
      end

      it "should return list of media_objects that the user is authorized to view" do
        get 'index', format: 'json'
        expect(json.count).to eq(1)
        expect(json.first['id']).to eq(media_object.id)
        expect(json.first['title']).to eq(media_object.title)
        expect(json.first['collection']).to eq(media_object.collection.name)
        expect(json.first['main_contributors']).to eq(media_object.creator)
        expect(json.first['publication_date']).to eq(media_object.date_created)
        expect(json.first['published_by']).to eq(media_object.avalon_publisher)
        expect(json.first['published']).to eq(media_object.published?)
        expect(json.first['summary']).to eq(media_object.abstract)
      end
    end
  end

  describe 'pagination' do
      let(:collection) { FactoryBot.create(:collection) }
      let(:administrator) { FactoryBot.create(:administrator) }
      subject(:json) { JSON.parse(response.body) }
      before do
        5.times { FactoryBot.create(:published_media_object, visibility: 'public', collection: collection) }
        ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
        request.headers['Avalon-Api-Key'] = 'secret_token'
        get 'index', params: { format:'json', per_page: '2' }
      end
      it 'should paginate' do
        expect(json.count).to eq(2)
        expect(response.headers['Per-Page']).to eq('2')
        expect(response.headers['Total']).to eq('5')
      end
  end

  describe "#show" do
    let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }

    context "Known items should be retrievable" do
      context 'with fedora 3 pid' do
        let!(:media_object) {FactoryBot.create(:published_media_object, visibility: 'public', identifier: [fedora3_pid])}
        let(:fedora3_pid) { 'avalon:1234' }

        it "should redirect" do
          expect(get :show, params: { id: fedora3_pid }).to redirect_to(media_object_url(media_object.id))
        end
      end

      it "should be accesible by its PID" do
        FactoryBot.create(:master_file, media_object: media_object)
        get :show, params: { id: media_object.id }
        expect(response.response_code).to eq(200)
      end

      it "should return an error if the PID does not exist" do
        get :show, params: { id: 'no-such-object' }
        expect(response).to render_template("errors/unknown_pid")
        expect(response.response_code).to eq(404)
      end

      it "should be available to a manager when unpublished" do
        login_user media_object.collection.managers.first
        FactoryBot.create(:master_file, media_object: media_object)
        get 'show', params: { id: media_object.id }
        expect(response).not_to redirect_to new_user_session_path
      end

      it "should provide a JSON stream description to the client" do
        part = FactoryBot.create(:master_file, media_object: media_object)
        get :show_stream_details, params: { id: media_object.id, content: part.id }, xhr: true
        json_obj = JSON.parse(response.body)
        expect(json_obj['is_video']).to eq(part.is_video?)
        expect(json_obj['link_back_url']).to eq(Rails.application.routes.url_helpers.id_section_media_object_url(media_object, part))
      end

      it "should provide a JSON stream description with permalink to the client" do
        part = FactoryBot.create(:master_file, media_object: media_object, permalink: 'https://permalink.host/path/id')
        get :show_stream_details, params: { id: media_object.id, content: part.id }, xhr: true
        json_obj = JSON.parse(response.body)
        expect(json_obj['link_back_url']).to eq('https://permalink.host/path/id')
      end

      it "should choose the correct default master_file" do
        mf1 = FactoryBot.create(:master_file, media_object: media_object)
        mf2 = FactoryBot.create(:master_file, media_object: media_object)
        expect(media_object.sections.first).to eq(mf1)
        media_object.sections = media_object.sections.reverse
        media_object.save!
        controller.instance_variable_set('@media_object', media_object)
        expect(media_object.sections.first).to eq(mf2)
        expect(controller.send('set_active_file')).to eq(mf2)
      end
    end

    context "Test lease access control" do
      let!(:media_object) { FactoryBot.create(:published_media_object, :with_master_file, visibility: 'private') }
      let!(:user) { FactoryBot.create(:user) }
      before :each do
        login_user user.user_key
      end
      it "should not be available to a user on an inactive lease" do
        media_object.governing_policies+=[Lease.create(begin_time: Date.today-2.day, end_time: Date.yesterday, inherited_read_users: [user.user_key])]
        media_object.save!
        get 'show', params: { id: media_object.id }
        expect(response).to render_template('errors/restricted_pid')
      end
      it "should be available to a user on an active lease" do
        media_object.governing_policies+=[Lease.create(begin_time: Date.yesterday, end_time: Date.tomorrow, inherited_read_users: [user.user_key])]
        media_object.save!
        get 'show', params: { id: media_object.id }
        expect(response.response_code).to eq(200)
      end
    end

    context "Conditional Share partials should be rendered" do
      let!(:media_object) { FactoryBot.create(:published_media_object, :with_master_file, visibility: 'public') }
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
      let(:cache) { Rails.cache }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.clear
      end

      it 'should cache .is_editor' do
        # Method will not cache if CDL is enabled and item is not checked out. Ensure CDL is disabled for testing.
        allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false)

        login_user media_object.collection.editors.first
        get :show, params: { id: media_object.id }
        expect(Rails.cache.instance_variable_get(:@data).keys.any?(/\-?\d+\/is_editor/)).to be_truthy
      end

      context 'With cdl enabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
        before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
        context "With check out" do
          context "Normal login" do
            it "administrators: should include lti, embed, and share" do
              login_as(:administrator)
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to render_template(:_share_resource)
              expect(response).to render_template(:_embed_resource)
              expect(response).to render_template(:_lti_url)
            end
            it "managers: should include lti, embed, and share" do
              login_user media_object.collection.managers.first
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to render_template(:_share_resource)
              expect(response).to render_template(:_embed_resource)
              expect(response).to render_template(:_lti_url)
            end
            it "editors: should include lti, embed, and share" do
              login_user media_object.collection.editors.first
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to render_template(:_share_resource)
              expect(response).to render_template(:_embed_resource)
              expect(response).to render_template(:_lti_url)
            end
            it "others: should include share, embed, and NOT lti" do
              login_as(:user)
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to render_template(:_share_resource)
              expect(response).to render_template(:_embed_resource)
              expect(response).to_not render_template(:_lti_url)
            end
          end
          context "LTI login" do
            it "administrators/managers/editors: should include lti, embed, and share" do
              login_lti 'administrator'
              lti_group = @controller.user_session[:virtual_groups].first
              FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to render_template(:_share_resource)
              expect(response).to render_template(:_embed_resource)
              expect(response).to render_template(:_lti_url)
            end
            it "others: should include only lti" do
              login_lti 'student'
              lti_group = @controller.user_session[:virtual_groups].first
              FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to_not render_template(:_share_resource)
              expect(response).to_not render_template(:_embed_resource)
              expect(response).to render_template(:_lti_url)
            end
          end
          context "No share tabs rendered" do
            before do
              @original_conditional_partials = controller.class.conditional_partials.deep_dup
              controller.class.conditional_partials[:share].each {|partial_name, conditions| conditions[:if] = false }
            end
            after do
              controller.class.conditional_partials = @original_conditional_partials
            end
            it "should not render Share button" do
              # allow(@controller).to receive(:evaluate_if_unless_configuration).and_return false
              # allow(@controller).to receive(:is_editor_or_not_lti).and_return false
              expect(response).to_not render_template(:_share)
            end
          end
          context "No LTI configuration" do
            around do |example|
              providers = Avalon::Authentication::Providers
              Avalon::Authentication::Providers = Avalon::Authentication::Providers.reject{|p| p[:provider] == :lti}
              example.run
              Avalon::Authentication::Providers = providers
            end
            it "should not include lti" do
              login_as(:administrator)
              FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: controller.current_user.id)
              get :show, params: { id: media_object.id }
              expect(response).to render_template(:_share_resource)
              expect(response).to render_template(:_embed_resource)
              expect(response).to_not render_template(:_lti_url)
            end
          end
        end
        context "Without check out" do
          context "Normal login" do
            it "administrators: should render checkout button in player, NOT share" do
              login_as(:administrator)
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
            it "managers: should render checkout button in player, NOT share" do
              login_user media_object.collection.managers.first
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
            it "editors: should render checkout button in player, NOT share" do
              login_user media_object.collection.editors.first
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
            it "others: should render checkout button in player, NOT share" do
              login_as(:user)
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
          end
          context "LTI login" do
            it "administrators/managers/editors: should render checkout button in player, NOT share" do
              login_lti 'administrator'
              lti_group = @controller.user_session[:virtual_groups].first
              FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
            it "others: should render checkout button in player, NOT share" do
              login_lti 'student'
              lti_group = @controller.user_session[:virtual_groups].first
              FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
          end
          context "No share tabs rendered" do
            before do
              @original_conditional_partials = controller.class.conditional_partials.deep_dup
              controller.class.conditional_partials[:share].each {|partial_name, conditions| conditions[:if] = false }
            end
            after do
              controller.class.conditional_partials = @original_conditional_partials
            end
            it "should not render Share button" do
              # allow(@controller).to receive(:evaluate_if_unless_configuration).and_return false
              # allow(@controller).to receive(:is_editor_or_not_lti).and_return false
              expect(response).to_not render_template(:_share)
            end
          end
          context "No LTI configuration" do
            around do |example|
              providers = Avalon::Authentication::Providers
              Avalon::Authentication::Providers = Avalon::Authentication::Providers.reject{|p| p[:provider] == :lti}
              example.run
              Avalon::Authentication::Providers = providers
            end
            it "should render checkout button in player, NOT share" do
              login_as(:administrator)
              get :show, params: { id: media_object.id }
              expect(response).not_to render_template(:_share_resource)
              expect(response).to render_template(:_embed_checkout)
            end
          end
        end
      end
      context "With cdl disabled" do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }
        context "Normal login" do
          it "administrators: should include lti, embed, and share" do
            login_as(:administrator)
            get :show, params: { id: media_object.id }
            expect(response).to render_template(:_share_resource)
            expect(response).to render_template(:_embed_resource)
            expect(response).to render_template(:_lti_url)
          end
          it "managers: should include lti, embed, and share" do
            login_user media_object.collection.managers.first
            get :show, params: { id: media_object.id }
            expect(response).to render_template(:_share_resource)
            expect(response).to render_template(:_embed_resource)
            expect(response).to render_template(:_lti_url)
          end
          it "editors: should include lti, embed, and share" do
            login_user media_object.collection.editors.first
            get :show, params: { id: media_object.id }
            expect(response).to render_template(:_share_resource)
            expect(response).to render_template(:_embed_resource)
            expect(response).to render_template(:_lti_url)
          end
          it "others: should include embed and share and NOT lti" do
            login_as(:user)
            get :show, params: { id: media_object.id }
            expect(response).to render_template(:_share_resource)
            expect(response).to render_template(:_embed_resource)
            expect(response).to_not render_template(:_lti_url)
          end
        end
        context "LTI login" do
          it "administrators/managers/editors: should include lti, embed, and share" do
            login_lti 'administrator'
            lti_group = @controller.user_session[:virtual_groups].first
            FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
            get :show, params: { id: media_object.id }
            expect(response).to render_template(:_share_resource)
            expect(response).to render_template(:_embed_resource)
            expect(response).to render_template(:_lti_url)
          end
          it "others: should include only lti" do
            login_lti 'student'
            lti_group = @controller.user_session[:virtual_groups].first
            FactoryBot.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
            get :show, params: { id: media_object.id }
            expect(response).to_not render_template(:_share_resource)
            expect(response).to_not render_template(:_embed_resource)
            expect(response).to render_template(:_lti_url)
          end
        end
        context "No share tabs rendered" do
          before do
            @original_conditional_partials = controller.class.conditional_partials.deep_dup
            controller.class.conditional_partials[:share].each {|partial_name, conditions| conditions[:if] = false }
          end
          after do
            controller.class.conditional_partials = @original_conditional_partials
          end
          it "should not render Share button" do
            # allow(@controller).to receive(:evaluate_if_unless_configuration).and_return false
            # allow(@controller).to receive(:is_editor_or_not_lti).and_return false
            expect(response).to_not render_template(:_share)
          end
        end
        context "No LTI configuration" do
          around do |example|
            providers = Avalon::Authentication::Providers
            Avalon::Authentication::Providers = Avalon::Authentication::Providers.reject{|p| p[:provider] == :lti}
            example.run
            Avalon::Authentication::Providers = providers
          end
          it "should not include lti" do
            login_as(:administrator)
            get :show, params: { id: media_object.id }
            expect(response).to render_template(:_share_resource)
            expect(response).to render_template(:_embed_resource)
            expect(response).to_not render_template(:_lti_url)
          end
        end
      end
    end

    context "correctly handle unfound streams/sections" do
      subject(:mo){FactoryBot.create(:media_object, :with_master_file)}
      before do
        login_user mo.collection.managers.first
      end
      it "redirects to first stream when currentStream is bad" do
        expect(get 'show', params: { id: mo.id, content: 'foo' }).to redirect_to(media_object_path(id: mo.id))
      end
      it "responds with 404 when non-existant section is requested" do
        get 'show', params: { id: mo.id, part: 100 }
        expect(response.code).to eq('404')
      end
    end

    ## NOTE: Test for MODS XML on page, which has been decided to be moved with item page re-design
    # context "correctly handle missing controlled vocabulary sections" do
    #   before do
    #     stub_const("ModsDocument::RIGHTS_STATEMENTS", nil)
    #   end
    #   it "should redirect to homepage if controlled_vocabulary.yml is incomplete" do
    #     get :show, params: { id: media_object.id }
    #     expect(response).to redirect_to(root_path)
    #     expect(flash[:error]).to be_present
    #   end
    # end

    describe 'Redirect back to media object after sign in' do
      let(:media_object){ FactoryBot.create(:media_object, visibility: 'private') }

      context 'Before sign in' do
        it 'persists the current url on the session' do
          get 'show', params: { id: media_object.id }
          expect(session[:user_return_to]).to eql media_object_path(media_object)
        end
      end

      context 'After sign in' do
        before do
          @user = FactoryBot.create(:user)
          @media_object = FactoryBot.create(:media_object, visibility: 'private', read_users: [@user.user_key] )
        end
        it 'redirects to the previous url' do
        end
        it 'removes the previous url from the session' do
        end
      end
    end

    context "Items should not be available to unauthorized users" do
      it "should redirect to restricted content page when not logged in and item is unpublished" do
        media_object.publish!(nil)
        expect(media_object).not_to be_published
        get 'show', params: { id: media_object.id }
        expect(response).to render_template('errors/restricted_pid')
      end

      it "should redirect to restricted content page when logged in and item is unpublished" do
        media_object.publish!(nil)
        expect(media_object).not_to be_published
        login_as :user
        get 'show', params: { id: media_object.id }
        expect(response).to render_template('errors/restricted_pid')
      end
    end

    context "with json format" do
      subject(:json) { JSON.parse(response.body) }
      let(:administrator) { FactoryBot.create(:administrator) }
      let!(:media_object) { FactoryBot.create(:all_fields_media_object) }
      let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object) }

      before do
        ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
        request.headers['Avalon-Api-Key'] = 'secret_token'
      end

      it "should return json for specific media_object" do
        # Run indexing job to ensure object isn't reified in this request
        perform_enqueued_jobs(only: MediaObjectIndexingJob)
        get 'show', params: { id: media_object.id, format:'json' }
        expect(json['id']).to eq(media_object.id)
        expect(json['title']).to eq(media_object.title)
        expect(json['collection']).to eq(media_object.collection.name)
        expect(json['collection_id']).to eq(media_object.collection.id)
        expect(json['main_contributors']).to eq(media_object.creator)
        expect(json['publication_date']).to eq(media_object.date_created)
        expect(json['published_by']).to eq(media_object.avalon_publisher)
        expect(json['published']).to eq(media_object.published?)
        expect(json['summary']).to eq(media_object.abstract)

        ingest_api_hash = media_object.to_ingest_api_hash(false)
        json['fields'].each do |k,v|
          # Known issue: identifiers are downcased when indexing to allow for case-insensitive searching
          if k.to_sym == :identifier
            expect(v).to eq(ingest_api_hash[:fields][k.to_sym].map(&:downcase))
          else
            expect(v).to eq(ingest_api_hash[:fields][k.to_sym])
          end
        end

        # Symbolize keys for master files and derivatives
        json['files'].each do |mf|
          mf.symbolize_keys!
          mf[:files].each { |d| d.symbolize_keys! }
        end
        expect(json['files']).to eq(media_object.to_ingest_api_hash(false)[:files])
        expect(json['files'].first[:id]).to eq(media_object.sections.first.id)
        expect(json['files'].first[:files].first[:id]).to eq(media_object.sections.first.derivatives.first.id)
      end

      it "should return 404 if requested media_object not present" do
        login_as(:administrator)
        get 'show', params: { id: 'doesnt_exist', format: 'json' }
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)["errors"].class).to eq Array
        expect(JSON.parse(response.body)["errors"].first.class).to eq String
      end

      context "with structure" do
        let!(:master_file) { FactoryBot.create(:master_file, :with_structure, media_object: media_object) }

        before do
          login_as(:administrator)
        end

        it "should not return structure by default" do
          get 'show', params: { id: media_object.id, format:'json' }
          expect(json['files'].first['structure']).to be_blank
        end

        it "should return structure inline if requested" do
          get 'show', params: { id: media_object.id, format:'json', include_structure: true }
          expect(json['files'].first['structure']).to eq master_file.structuralMetadata.content
        end

        it "should not return structure inline if requested not to" do
          get 'show', params: { id: media_object.id, format:'json', include_structure: false }
          expect(json['files'].first['structure']).not_to eq master_file.structuralMetadata.content
        end
      end

      context 'read from solr' do
      	it 'should not read from fedora' do
      	  perform_enqueued_jobs(only: MediaObjectIndexingJob)
      	  WebMock.reset_executed_requests!
          get 'show', params: { id: media_object.id, format:'json' }
      	  expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      	end

        context 'MO with identifier-less master file' do
          let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
          let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object, identifier: nil) }
          it 'should not read from fedora' do
            perform_enqueued_jobs(only: MediaObjectIndexingJob)
            WebMock.reset_executed_requests!
            get 'show', params: { id: media_object.id, format: 'json' }
            expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
          end
        end

        context 'MO with master file containing IndexedFiles' do
          let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
          let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, :with_thumbnail, :with_poster, :with_waveform, :with_captions, media_object: media_object, identifier: nil) }
          it 'should not read from fedora' do
            perform_enqueued_jobs(only: MediaObjectIndexingJob)
            WebMock.reset_executed_requests!
            get 'show', params: { id: media_object.id, format: 'json' }
            expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
          end
        end
      end
    end

    context 'misformed NOID' do
      it 'should redirect to the requested media object if valid' do
        get 'show', params: { id: "#{media_object.id}] !-()" }
        expect(response).to redirect_to(media_object_path(id: media_object.id))
      end
      it 'should redirect to unknown_pid page if invalid' do
        get 'show', params: { id: "nonvalid noid]" }
        expect(response).to render_template("errors/unknown_pid")
        expect(response.response_code).to eq(404)
      end
    end

    context 'read from solr' do
      let!(:media_object) { FactoryBot.create(:published_media_object, :with_master_file, visibility: 'public') }
      it 'should not read from fedora' do
        perform_enqueued_jobs(only: MediaObjectIndexingJob)
        WebMock.reset_executed_requests!
        get 'show', params: { id: media_object.id }
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end

      context 'media object with identifier-less master file' do
        let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object, identifier: nil) }
        it 'should not read from fedora' do
          perform_enqueued_jobs(only: MediaObjectIndexingJob)
          WebMock.reset_executed_requests!
          get 'show', params: { id: media_object.id }
          expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
        end
      end

      context 'media object with master file containing IndexedFiles' do
        let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, :with_thumbnail, :with_poster, :with_waveform, :with_captions, media_object: media_object, identifier: nil) }
        it 'should not read from fedora' do
          perform_enqueued_jobs(only: MediaObjectIndexingJob)
          WebMock.reset_executed_requests!
          get 'show', params: { id: media_object.id }
          expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
        end
      end
    end
  end

  describe "#destroy" do
    let!(:collection) { FactoryBot.create(:collection) }
    before(:each) do
      login_user collection.managers.first
      allow_any_instance_of(MasterFile).to receive(:stop_processing!)
    end

    around(:example) do |example|
      # In Rails 5.1+ this can be restricted to whitelist jobs allowed to be performed
      perform_enqueued_jobs { example.run }
    end

    it "should remove a MediaObject with a single MasterFiles" do
      media_object = FactoryBot.create(:media_object, :with_master_file, collection: collection)
      delete :destroy, params: { id: media_object.id }
      expect(flash[:notice]).to include("media object deleted")
      expect(MediaObject.exists?(media_object.id)).to be_falsey
      expect(MasterFile.exists?(media_object.section_ids.first)).to be_falsey
    end

    it "should remove a MediaObject with multiple MasterFiles" do
      media_object = FactoryBot.create(:media_object, :with_master_file, collection: collection)
      FactoryBot.create(:master_file, media_object: media_object)
      section_ids = media_object.section_ids
      media_object.reload
      delete :destroy, params: { id: media_object.id }
      expect(flash[:notice]).to include("media object deleted")
      expect(MediaObject.exists?(media_object.id)).to be_falsey
      section_ids.each { |mf_id| expect(MasterFile.exists?(mf_id)).to be_falsey }
    end

    it "should fail when id doesn't exist" do
      delete :destroy, params: { id: 'this-id-is-fake' }
      expect(response.code).to eq '404'
    end

    it "should remove multiple items" do
      media_objects = []
      3.times { media_objects << FactoryBot.create(:media_object, collection: collection) }
      delete :destroy, params: { id: media_objects.map(&:id) }
      expect(flash[:notice]).to include('3 media objects')
      media_objects.each {|mo| expect(MediaObject.exists?(mo.id)).to be_falsey }
    end

    it "should remove child supplemental files" do
      supplemental_file = FactoryBot.create(:supplemental_file)
      media_object = FactoryBot.create(:media_object, collection: collection, supplemental_files: [supplemental_file] )
      expect(SupplementalFile.exists?(supplemental_file.id)).to be_truthy
      delete :destroy, params: { id: media_object.id }
      expect(SupplementalFile.exists?(supplemental_file.id)).to be_falsey
    end

    it "should remove section supplemental files" do
      supplemental_file = FactoryBot.create(:supplemental_file)
      media_object = FactoryBot.create(:media_object, collection: collection )
      master_file = FactoryBot.create(:master_file, media_object: media_object, supplemental_files: [supplemental_file])
      expect(SupplementalFile.exists?(supplemental_file.id)).to be_truthy
      delete :destroy, params: { id: media_object.id }
      expect(SupplementalFile.exists?(supplemental_file.id)).to be_falsey
    end
  end

  describe "#confirm_remove" do
    let!(:collection) { FactoryBot.create(:collection) }
    before(:each) do
      login_user collection.managers.first
    end

    it "renders restricted content page when user does not have ability to delete all items" do
      media_object = FactoryBot.create(:media_object)
      expect(controller.current_ability.can? :destroy, media_object).to be_falsey
      expect(get :confirm_remove, params: { id: media_object.id }).to render_template('errors/restricted_pid')
    end
    it "displays confirmation form" do
      media_object = FactoryBot.create(:media_object, collection: collection)
      expect(controller.current_ability.can? :destroy, media_object).to be_truthy
      expect(get :confirm_remove, params: { id: media_object.id }).to render_template(:confirm_remove)
    end
    it "displays confirmation form even if user does not have ability to delete some items" do
      media_object1 = FactoryBot.create(:media_object)
      media_object2 = FactoryBot.create(:media_object, collection: collection)
      expect(controller.current_ability.can? :destroy, media_object1).to be_falsey
      expect(controller.current_ability.can? :destroy, media_object2).to be_truthy
      expect(get :confirm_remove, params: { id: [media_object1.id, media_object2.id] }).to render_template(:confirm_remove)
    end
    it "displays confirmation form for administrators" do
      login_as :administrator
      media_object = FactoryBot.create(:media_object, collection: collection)
      expect(controller.current_ability.can? :destroy, media_object).to be_truthy
      expect(get :confirm_remove, params: { id: media_object.id }).to render_template(:confirm_remove)
    end
  end

  describe "#update_status" do

    let!(:collection) { FactoryBot.create(:collection) }
    before(:each) do
      login_user collection.managers.first
      request.env["HTTP_REFERER"] = '/'
    end

    context 'publishing' do
      before(:all) do
        Permalink.on_generate { |obj| "http://example.edu/permalink" }
      end

      after(:all) do
        Permalink.on_generate { nil }
      end

      it 'publishes media object' do
        media_object = FactoryBot.create(:media_object, collection: collection)
        get 'update_status', params: { id: media_object.id, status: 'publish' }
        media_object.reload
        expect(media_object).to be_published
        expect(media_object.permalink).to be_present
      end

      it "should publish multiple items" do
        media_objects = []
        3.times { media_objects << FactoryBot.create(:media_object, collection: collection) }
        get 'update_status', params: { id: media_objects.map(&:id), status: 'publish' }
        expect(flash[:notice]).to include('3 media objects')
        media_objects.each do |mo|
          mo.reload
          expect(mo).to be_published
          expect(mo.permalink).to be_present
        end
      end

      context "should fail when" do
        it "id doesn't exist" do
          get 'update_status', params: { id: 'this-id-is-fake', status: 'publish' }
          expect(response.code).to eq '404'
        end

        it "item is invalid" do
          media_object = FactoryBot.create(:media_object, collection: collection)
          media_object.title = nil
          media_object.workflow.last_completed_step = 'file-upload'
          media_object.save!(validate: false)
          get 'update_status', params: { id: media_object.id, status: 'publish' }
          expect(flash[:notice]).to eq("Unable to publish item: #{media_object&.title} (#{media_object.id}) (missing required fields)")
          media_object.reload
          expect(media_object).not_to be_published
        end

        it "item is invalid and no last_completed_step" do
          media_object = FactoryBot.create(:media_object, collection: collection)
          media_object.title = nil
          media_object.workflow.last_completed_step = ''
          media_object.save!(validate: false)
          get 'update_status', params: { id: media_object.id, status: 'publish' }
          expect(flash[:notice]).to eq("Unable to publish item: #{media_object&.title} (#{media_object.id}) (missing required fields)")
          media_object.reload
          expect(media_object).not_to be_published
        end
      end
    end

    context 'unpublishing' do
      it 'unpublishes media object' do
        media_object = FactoryBot.create(:published_media_object, collection: collection)
        get 'update_status', params: { :id => media_object.id, :status => 'unpublish' }
        media_object.reload
        expect(media_object).not_to be_published
      end

      it 'unpublishes invalid items' do
        media_object = FactoryBot.create(:published_media_object, collection: collection)
        media_object.title = nil
        media_object.save!(validate: false)
        get 'update_status', params: { id: media_object.id, status: 'unpublish' }
        media_object.reload
        expect(media_object).not_to be_published
      end

      it 'unpublishes invalid items and no last completed step' do
        media_object = FactoryBot.create(:published_media_object, collection: collection)
        media_object.title = nil
        media_object.workflow.last_completed_step = ''
        media_object.save!(validate: false)
        get 'update_status', params: { id: media_object.id, status: 'unpublish' }
        media_object.reload
        expect(media_object).not_to be_published
      end

      context "should fail when" do
        it "id doesn't exist" do
          get 'update_status', params: { id: 'this-id-is-fake', status: 'unpublish' }
          expect(response.code).to eq '404'
        end
      end

      it "should unpublish multiple items" do
        media_objects = []
        3.times { media_objects << FactoryBot.create(:published_media_object, collection: collection) }
        get 'update_status', params: { id: media_objects.map(&:id), status: 'unpublish' }
        expect(flash[:notice]).to include('3 media objects')
        media_objects.each do |mo|
          mo.reload
          expect(mo).not_to be_published
        end
      end
    end
  end

  describe "#save" do
    it 'removes bookmarks that are no longer viewable' do
      media_object = FactoryBot.create(:published_media_object)
      user = FactoryBot.create(:public)
      bookmark = Bookmark.create(document_id: media_object.id, user: user)
      login_user media_object.collection.managers.first
      request.env["HTTP_REFERER"] = '/'
      expect {
        get 'update_status', params: { id: media_object.id, status: 'unpublish' }
      }.to change { Bookmark.exists? bookmark.id }.from( true ).to( false )
    end
  end

  describe "#update" do
    it 'updates the order' do

      media_object = FactoryBot.create(:media_object)
      2.times do
        mf = FactoryBot.create(:master_file)
        mf.media_object = media_object
        mf.save
      end
      section_ids = media_object.section_ids
      media_object.save

      login_user media_object.collection.managers.first

      put 'update', params: { :id => media_object.id, :master_file_ids => section_ids.reverse, :step => 'structure' }
      media_object.reload
      expect(media_object.section_ids).to eq section_ids.reverse
    end
    it 'sets the MIME type' do
      media_object = FactoryBot.create(:media_object)
      master_file = FactoryBot.create(:master_file, :with_derivative, media_object: media_object)
      media_object.reload # Reload here to force reloading master file solr docs used in #set_media_types!
      media_object.set_media_types!
      expect(media_object.format).to eq(["video/mp4"])
    end

    context 'large objects' do
      before(:all) do
        Permalink.on_generate { |obj| sleep(0.5); "http://example.edu/permalink" }
      end

      after(:all) do
        Permalink.on_generate { nil }
      end

      let!(:media_object) do
        mo = FactoryBot.create(:published_media_object)
        10.times { FactoryBot.create(:master_file, :with_derivative, media_object: mo) }
        mo
      end

      it "should update all the labels" do
        login_user media_object.collection.managers.first
        part_params = {}
        media_object.sections.each_with_index { |mf,i| part_params[mf.id] = { id: mf.id, title: "Part #{i}", permalink: '', poster_offset: '00:00:00.000' } }
        params = { id: media_object.id, master_files: part_params, save: 'Save', step: 'file-upload', donot_advance: 'true' }
        patch 'update', params: params
        media_object.reload
        media_object.sections.each_with_index do |mf,i|
          expect(mf.title).to eq "Part #{i}"
        end
      end
    end

    context "access controls" do
      let!(:media_object) { FactoryBot.create(:media_object) }
      let!(:user) { Faker::Internet.email }
      let!(:group) { Faker::Lorem.word }
      let!(:classname) { Faker::Lorem.word }
      let!(:ipaddr) { Faker::Internet.ip_v4_address }
      before(:each) { login_user media_object.collection.managers.first }

      context "grant and revoke special read access" do
        it "grants and revokes special read access to users" do
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add' } }.to change { media_object.reload.read_users }.from([]).to([user])
          expect {put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', remove_user: user, submit_remove_user: 'Remove' } }.to change { media_object.reload.read_users }.from([user]).to([])
        end
        it "grants and revokes special read access to groups" do
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_group: group, submit_add_group: 'Add' } }.to change { media_object.reload.read_groups }.from([]).to([group])
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', remove_group: group, submit_remove_group: 'Remove' } }.to change { media_object.reload.read_groups }.from([group]).to([])
        end
        it "grants and revokes special read access to external groups" do
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_class: classname, submit_add_class: 'Add' } }.to change { media_object.reload.read_groups }.from([]).to([classname])
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', remove_class: classname, submit_remove_class: 'Remove' } }.to change { media_object.reload.read_groups }.from([classname]).to([])
        end
        it "grants and revokes special read access to ips" do
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_ipaddress: ipaddr, submit_add_ipaddress: 'Add' } }.to change { media_object.reload.read_groups }.from([]).to([ipaddr])
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', remove_ipaddress: ipaddr, submit_remove_ipaddress: 'Remove' } }.to change { media_object.reload.read_groups }.from([ipaddr]).to([])
        end
      end

      context "grant and revoke time-based special read access" do
        it "should grant and revoke time-based access for users" do
          expect {
            put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.yesterday, add_user_end: Date.tomorrow }
            media_object.reload
          }.to change{media_object.leases.count}.by(1)
          expect(media_object.leases).not_to be_empty
          lease_id = media_object.reload.leases.first.id
          expect {
            put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', remove_lease: lease_id }
            media_object.reload
          }.to change{media_object.leases.count}.by(-1)
        end
      end

      context "must validate lease date ranges" do
        it "should accept valid date range for lease" do
          expect {
            put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.today, add_user_end: Date.tomorrow }
            media_object.reload
          }.to change{media_object.leases.count}.by(1)
        end
        it "should reject reverse date range for lease" do
          expect {
            put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.tomorrow, add_user_end: Date.today }
            media_object.reload
          }.not_to change{media_object.leases.count}
        end
        it "should accept missing begin date and set it to today" do
          expect {
            put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: '', add_user_end: Date.tomorrow }
            media_object.reload
          }.to change{media_object.leases.count}.by(1)
          expect(media_object.leases.first.begin_time).to eq(Date.today)
        end
        it "should reject missing end date" do
          expect {
            put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.tomorrow, add_user_end: '' }
            media_object.reload
          }.not_to change{media_object.leases.count}
        end
      end

      context "lending period" do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
        before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
        it "sets a custom lending period" do
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_lending_period_days: 7, add_lending_period_hours: 8 } }.to change { media_object.reload.lending_period }.to(633600)
        end

        it "returns error if invalid" do
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_lending_period_days: -1, add_lending_period_hours: -1 } }.not_to change { media_object.reload.lending_period }
          expect(flash[:error]).to be_present
          expect(flash[:error]).to eq("Lending period must be greater than 0.")
          put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_lending_period_days: 1, add_lending_period_hours: -1 }
          expect(flash[:error]).to be_present
          expect(flash[:error]).to eq("Lending period hours needs to be a positive integer.")
          put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_lending_period_days: -1, add_lending_period_hours: 1 }
          expect(flash[:error]).to be_present
          expect(flash[:error]).to eq("Lending period days needs to be a positive integer.")
          expect { put :update, params: { id: media_object.id, step: 'access-control', donot_advance: 'true', add_lending_period_days: 0, add_lending_period_hours: 0 } }.not_to change { media_object.reload.lending_period }
          expect(flash[:error]).to be_present
          expect(flash[:error]).to eq("Lending period must be greater than 0.")
        end
      end
    end

    context 'resource description' do
      context 'bib import' do
        require 'avalon/bib_retriever'
        let(:media_object) { FactoryBot.create(:media_object) }
        before do
          login_as 'administrator'
        end

        it 'does nothing when the bib id is blank or missing' do
          dbl = double("BibRetriever")
          allow(Avalon::BibRetriever).to receive(:instance).and_return(dbl)
          expect(dbl).not_to receive(:get_record)
          put :update, params: { id: media_object.id, step: 'resource-description', media_object: { import_bib_record: 'yes', bibliographic_id: ' ', bibliographic_id_label: 'local' } }
        end
      end
    end
  end

  describe "#show_progress" do
    it "should return information about the processing state of the media object's sections" do
      media_object =  FactoryBot.create(:media_object, :with_master_file)
      login_as 'administrator'
      get :show_progress, params: { id: media_object.id, format: 'json' }
      expect(JSON.parse(response.body)["overall"]).to_not be_empty
    end
    it "should return information about the processing state of the media object's sections for managers" do
      media_object =  FactoryBot.create(:media_object, :with_master_file)
      login_user media_object.collection.managers.first
      get :show_progress, params: { id: media_object.id, format: 'json' }
      expect(JSON.parse(response.body)["overall"]).to_not be_empty
    end
    it "should return something even if the media object has no sections" do
      media_object = FactoryBot.create(:media_object)
      login_as 'administrator'
      get :show_progress, params: { id: media_object.id, format: 'json' }
      expect(JSON.parse(response.body)["overall"]).to_not be_empty
    end
  end

  describe "#set_session_quality" do
    it "should set the posted quality in the session" do
      login_as 'administrator'
      post :set_session_quality, params: { quality: 'crazy_high' }
      expect(@request.session[:quality]).to eq('crazy_high')
    end
  end

  describe "#add_to_playlist" do
    let(:media_object) { FactoryBot.create(:fully_searchable_media_object, title: 'Test Item') }
    let(:master_file) { FactoryBot.create(:master_file, media_object: media_object, title: 'Test Section') }
    let(:master_file_with_structure) { FactoryBot.create(:master_file, :with_structure, media_object: media_object) }
    let(:user) { login_as :user }
    let(:playlist) { FactoryBot.create(:playlist, user: user) }

    before do
      media_object.sections = [master_file, master_file_with_structure]
    end

    it "should create a single playlist_item for a single master_file" do
      expect {
        post :add_to_playlist, params: { id: media_object.id, post: { playlist_id: playlist.id, masterfile_id: media_object.section_ids[0], playlistitem_scope: 'section' } }
      }.to change { playlist.items.count }.from(0).to(1)
      expect(playlist.items[0].title).to eq("#{media_object.title} - #{media_object.sections[0].title}")
    end
    it "should create playlist_items for each span in a single master_file's structure" do
      expect {
        post :add_to_playlist, params: { id: media_object.id, post: { playlist_id: playlist.id, masterfile_id: media_object.section_ids[1], playlistitem_scope: 'structure' } }
      }.to change { playlist.items.count }.from(0).to(13)
      expect(playlist.items[0].title).to eq("Test Item - CD 1 - Copland, Three Piano Excerpts from Our Town - Track 1. Story of Our Town")
      expect(playlist.items[12].title).to eq("Test Item - CD 1 - Track 13. Copland, Danzon Cubano")
    end
    it "should create a single playlist_item for each master_file in a media_object" do
      expect {
        post :add_to_playlist, params: { id: media_object.id, post: { playlist_id: playlist.id, playlistitem_scope: 'section' } }
      }.to change { playlist.items.count }.from(0).to(2)
      expect(playlist.items[0].title).to eq(media_object.sections[0].embed_title)
      expect(playlist.items[1].title).to eq(media_object.sections[1].embed_title)
    end
    it "should create playlist_items for each span in a master_file structures in a media_object" do
      expect {
        post :add_to_playlist, params: { id: media_object.id, post: { playlist_id: playlist.id, playlistitem_scope: 'structure' } }
      }.to change { playlist.items.count }.from(0).to(14)
      expect(response.response_code).to eq(200)
      expect(playlist.items[0].title).to eq("#{media_object.title} - #{media_object.sections[0].title}")
      expect(playlist.items[13].title).to eq("Test Item - CD 1 - Track 13. Copland, Danzon Cubano")
    end
    it 'redirects with flash message when playlist is owned by another user' do
      login_as :user
      other_playlist = FactoryBot.create(:playlist)
      post :add_to_playlist, params: { id: media_object.id, post: { playlist_id: other_playlist.id, masterfile_id: media_object.section_ids[0], playlistitem_scope: 'section' } }
      expect(response).to have_http_status(403)
      expect(JSON.parse(response.body).symbolize_keys).to eq({message: "<p>You are not authorized to update this playlist.</p>", status: 403})
    end

    context 'read from solr' do
      it 'should not read from fedora' do
        media_object
        perform_enqueued_jobs(only: MediaObjectIndexingJob)
        WebMock.reset_executed_requests!
        post :add_to_playlist, params: { id: media_object.id, post: { playlist_id: playlist.id, masterfile_id: media_object.section_ids[0], playlistitem_scope: 'section' } }
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end
    end
  end

  describe 'deliver_content' do
    before do
      login_as :administrator
    end

    let(:media_object) { FactoryBot.create(:published_media_object) }

    it 'returns descMetadata' do
      get :deliver_content, params: { id: media_object.id, file: 'descMetadata' }
      expect(response.status).to eq 200
      expect(response.content_type).to eq 'text/xml; charset=utf-8'
      expect(response.body).to eq media_object.descMetadata.content
    end
  end

  describe 'move_preview' do
    before do
      login_as :administrator
    end

    let(:media_object) { FactoryBot.create(:published_media_object) }

    it 'returns a json preview of the media object' do
      get :move_preview, params: { id: media_object.id, format: 'json' }
      expect(response.status).to eq 200
      expect(response.content_type).to eq 'application/json; charset=utf-8'
      json_preview = JSON.parse(response.body)
      expect(json_preview.keys).to eq ['id', 'title', 'collection', 'main_contributors', 'publication_date', 'published_by', 'published']
    end

    context 'as manager' do
      before do
        login_user media_object.collection.managers.first
      end

      let(:media_object) { FactoryBot.create(:published_media_object) }

      it 'returns a json preview of the media object' do
        get :move_preview, params: { id: media_object.id, format: 'json' }
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/json; charset=utf-8'
        json_preview = JSON.parse(response.body)
        expect(json_preview.keys).to eq ['id', 'title', 'collection', 'main_contributors', 'publication_date', 'published_by', 'published']
      end
    end

    context 'as end user' do
      before do
        login_as :student
      end

      let(:media_object) { FactoryBot.create(:published_media_object) }

      it 'returns unauthorized' do
        get :move_preview, params: { id: media_object.id, format: 'json' }
        expect(response.status).to eq 401
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#manifest' do
    before do
      login_as :administrator
    end

    context 'with supplemental files' do
      let(:mf_supplemental_file) { FactoryBot.create(:supplemental_file) }
      let(:mo_supplemental_file) { FactoryBot.create(:supplemental_file) }
      let(:master_file) { FactoryBot.create(:master_file, media_object: media_object, supplemental_files: [mf_supplemental_file]) }
      let(:media_object) { FactoryBot.create(:published_media_object, supplemental_files: [mo_supplemental_file]) }

      before do
        mf_supplemental_file.parent_id = master_file.id
        mo_supplemental_file.parent_id = media_object.id
        mf_supplemental_file.save
        mo_supplemental_file.save
      end

      it 'should link to proper object route in rendering section' do
        get 'manifest', params: { id: media_object.id, format: 'json' }
        parsed_response = JSON.parse(response.body)
        mo_rendering = parsed_response['rendering'].first
        expect(mo_rendering['id']).to eq Rails.application.routes.url_helpers.media_object_supplemental_file_url(id: mo_supplemental_file.id, media_object_id: media_object.id)
        item = parsed_response['items'].first
        mf_rendering = item['rendering'].first
        expect(mf_rendering['id']).to eq Rails.application.routes.url_helpers.master_file_supplemental_file_url(id: mf_supplemental_file.id, master_file_id: master_file.id)
      end
    end
 
    context 'read from solr' do
      let!(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object) }
      let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
      it 'should not read from fedora' do
        perform_enqueued_jobs(only: MediaObjectIndexingJob)
        WebMock.reset_executed_requests!
        get 'manifest', params: { id: media_object.id, format: 'json' }
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end
    end

    context 'caching' do
      let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
      subject { Rails.cache.read("#{SpeedyAF::Proxy::MediaObject.find(media_object.id).cache_key_with_version}/iiif_manifest") }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        # Range ids are randomly generated. Force the id to a known value so we can equality match.
        allow_any_instance_of(IIIFManifest::V3::ManifestBuilder::RangeBuilder).to receive(:path).and_return('range')
        presenter = IiifManifestPresenter.new(media_object: media_object, master_files: [])
        @manifest = IIIFManifest::V3::ManifestFactory.new(presenter).to_h
      end

      after do
        Rails.cache.clear
      end

      it 'should cache the iiif manifest' do
        get 'manifest', params: { id: media_object.id, format: 'json' }
        expect(subject).to be_a(IIIFManifest::V3::ManifestBuilder::IIIFManifest)
        expect(subject.to_json).to eq(@manifest.to_json)
      end

      it 'should update the cache when the media object is updated' do
        get 'manifest', params: { id: media_object.id, format: 'json' }
        old_manifest = subject.to_json
        media_object.title = 'Test'
        # Update timestamps available from the SpeedyAF proxy are whole second values.
        # This should typically not be an issue in production, but the test can run
        # quick enough that the version number remains the same. Explicitly jump forward
        # in time to make sure the update timestamp is different. Using travel_to is
        # hopefully more performant than `sleep 1`.
        travel_to(Time.current + 1.second) do
          media_object.save!
        end
        new_presenter = IiifManifestPresenter.new(media_object: media_object, master_files: [])
        new_manifest = IIIFManifest::V3::ManifestFactory.new(new_presenter).to_h.to_json
        get 'manifest', params: { id: media_object.id, format: 'json' }
        new_cache = Rails.cache.read("#{SpeedyAF::Proxy::MediaObject.find(media_object.id).cache_key_with_version}/iiif_manifest")
        expect(new_cache).to be_a(IIIFManifest::V3::ManifestBuilder::IIIFManifest)
        expect(new_cache.to_json).to_not eq(old_manifest)
        expect(new_cache.to_json).to eq(new_manifest)
      end
    end
  end

  describe '#tree' do
    context 'read from solr' do
      let!(:media_object) { FactoryBot.create(:published_media_object, :with_master_file, visibility: 'public') }
      it 'should not read from fedora' do
        login_as(:administrator)
        perform_enqueued_jobs(only: MediaObjectIndexingJob)
        WebMock.reset_executed_requests!
        get 'tree', params: { id: media_object.id }
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end
    end
  end
end
