# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

describe MediaObjectsController, type: :controller do
  render_views

  before(:each) do
    request.env["HTTP_REFERER"] = '/'
  end

  describe 'security' do
    let(:media_object) { FactoryGirl.create(:media_object) }
    let(:collection) { FactoryGirl.create(:collection) }
    describe 'ingest api' do
      it "all routes should return 401 when no token is present" do
        expect(get :index, format: 'json').to have_http_status(401)
        expect(get :show, id: media_object.id, format: 'json').to have_http_status(401)
        expect(post :create, format: 'json').to have_http_status(401)
        expect(put :update, id: media_object.id, format: 'json').to have_http_status(401)
      end
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :index, format: 'json').to have_http_status(403)
        expect(get :show, id: media_object.id, format: 'json').to have_http_status(403)
        expect(post :create, format: 'json').to have_http_status(403)
        expect(put :update, id: media_object.id, format: 'json').to have_http_status(403)
      end
    end
    describe 'normal auth' do
      context 'with unauthenticated user' do
        #New is isolated here due to issues caused by the controller instance not being regenerated
        it "should redirect to sign in" do
          expect(get :new).to redirect_to(new_user_session_path)
        end
        it "all routes should redirect to sign in" do
          expect(get :show, id: media_object.id).to redirect_to(new_user_session_path)
          expect(get :show_progress, id: media_object.id, format: 'json').to have_http_status(401)
          expect(get :edit, id: media_object.id).to redirect_to(new_user_session_path)
          expect(get :confirm_remove, id: media_object.id).to redirect_to(new_user_session_path)
          expect(post :create).to redirect_to(new_user_session_path)
          expect(put :update, id: media_object.id).to redirect_to(new_user_session_path)
          expect(put :update_status, id: media_object.id).to redirect_to(new_user_session_path)
          expect(get :tree, id: media_object.id).to redirect_to(new_user_session_path)
          expect(get :deliver_content, id: media_object.id, datastream: 'descMetadata').to redirect_to(new_user_session_path)
          expect(delete :destroy, id: media_object.id).to redirect_to(new_user_session_path)
        end
      end
      context 'with end-user' do
        before do
          login_as :user
        end
        #New is isolated here due to issues caused by the controller instance not being regenerated
        it "should redirect to /" do
          expect(get :new).to redirect_to(root_path)
        end
        it "all routes should redirect to /" do
          expect(get :show, id: media_object.id).to redirect_to(root_path)
          expect(get :show_progress, id: media_object.id, format: 'json').to redirect_to(root_path)
          expect(get :edit, id: media_object.id).to redirect_to(root_path)
          expect(get :confirm_remove, id: media_object.id).to redirect_to(root_path)
          expect(post :create).to redirect_to(root_path)
          expect(put :update, id: media_object.id).to redirect_to(root_path)
          expect(put :update_status, id: media_object.id).to redirect_to(root_path)
          expect(get :tree, id: media_object.id).to redirect_to(root_path)
          expect(get :deliver_content, id: media_object.id, datastream: 'descMetadata').to redirect_to(root_path)
          expect(delete :destroy, id: media_object.id).to redirect_to(root_path)
        end
      end
    end
  end

  context "JSON API methods" do
    let!(:collection) { FactoryGirl.create(:collection) }
    let!(:testdir) {'spec/fixtures/'}
    let!(:filename) {'videoshort.high.mp4'}
    let!(:absolute_location) {Rails.root.join(File.join(testdir, filename)).to_s}
    let!(:structure) {File.read(File.join(testdir, 'structure.xml'))}
    let!(:bib_id) { '7763100' }
    let!(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
    let!(:sru_response) { File.read(File.expand_path("../../fixtures/#{bib_id}.xml",__FILE__)) }
    let!(:masterfile) {{
        file_location: absolute_location,
        label: "Part 1",
        files: [{label: 'quality-high',
                  id: 'track-1',
                  url: absolute_location,
                  duration: "6315",
                  mime_type:  "video/mp4",
                  audio_bitrate: "127716.0",
                  audio_codec: "AAC",
                  video_bitrate: "1000000.0",
                  video_codec: "AVC",
                  width: "640",
                  height: "480" },
                {label: 'quality-medium',
                  id: 'track-2',
                  url: absolute_location,
                  duration: "6315",
                  mime_type: "video/mp4",
                  audio_bitrate: "127716.0",
                  audio_codec: "AAC",
                  video_bitrate: "1000000.0",
                  video_codec: "AVC",
                  width: "640",
                  height: "480" }
               ],
        file_location: absolute_location,
        file_checksum: "7ae24368ccb7a6c6422a14ff73f33c9a",
        file_size: "199160",
        duration: "6315",
        display_aspect_ratio: "1.7777777777777777",
        original_frame_size: "640x480",
        file_format: "Moving image",
        poster_offset: "0:02",
        thumbnail_offset: "0:02",
        date_ingested: "2015-12-31",
        workflow_name: "avalon",
        percent_complete: "100.0",
        percent_succeeded: "100.0",
        percent_failed: "0",
        status_code: "COMPLETED",
        other_identifier: '40000000045312',
        structure: structure
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
      :other_identifier
    ]}
    describe "#create" do
      context 'using api' do
        before do
           request.headers['Avalon-Api-Key'] = 'secret_token'
        end
        it "should respond with 422 if collection not found" do
          post 'create', format: 'json', collection_id: "avalon:doesnt_exist"
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)["errors"].class).to eq Array
          expect(JSON.parse(response.body)["errors"].first.class).to eq String
        end
        it "should create a new mediaobject" do
          media_object = FactoryGirl.create(:multiple_entries)
          fields = media_object.attributes.select {|k,v| descMetadata_fields.include? k.to_sym }
          post 'create', format: 'json', fields: fields, files: [masterfile], collection_id: collection.pid
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.title).to eq media_object.title
          expect(new_media_object.creator).to eq media_object.creator
          expect(new_media_object.date_issued).to eq media_object.date_issued
          expect(new_media_object.parts_with_order).to eq new_media_object.parts
          expect(new_media_object.duration).to eq '6315'
          expect(new_media_object.format).to eq 'video/mp4'
          expect(new_media_object.resource_type).to eq ['moving image']
          expect(new_media_object.parts.first.date_ingested).to eq('2015-12-31T00:00:00Z')
          expect(new_media_object.parts.first.DC.identifier).to include('40000000045312')
          expect(new_media_object.parts.first.derivatives.count).to eq(2)
          expect(new_media_object.parts.first.derivatives.first.location_url).to eq(absolute_location)          
        end
        it "should create a new mediaobject with successful bib import" do
          Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
          FakeWeb.register_uri :get, sru_url, body: sru_response
          fields = { bibliographic_id: bib_id }
          post 'create', format: 'json', import_bib_record: true, fields: fields, files: [masterfile], collection_id: collection.pid
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.bibliographic_id).to eq(['local', bib_id])
          expect(new_media_object.title).to eq('245 A : B F G K N P S')
        end
      end
    end
    describe "#update" do
      context 'using api' do
        before do
          request.headers['Avalon-Api-Key'] = 'secret_token'
        end
        let!(:media_object) { FactoryGirl.create(:media_object_with_master_file) }
        it "should route json format to #json_update" do
          assert_routing({ path: 'media_objects/avalon:1.json', method: :put },
             { controller: 'media_objects', action: 'json_update', id: 'avalon:1', format: 'json' })
        end
        it "should route unspecified format to #update" do
          assert_routing({ path: 'media_objects/avalon:1', method: :put },
             { controller: 'media_objects', action: 'update', id: 'avalon:1', format: 'html' })
        end
        it "should update a mediaobject's metadata" do
          old_title = media_object.title
          put 'json_update', format: 'json', id: media_object.pid, fields: {title: old_title+'new'}, collection_id: media_object.collection_id
          expect(JSON.parse(response.body)['id'].class).to eq String
          expect(JSON.parse(response.body)).not_to include('errors')
          media_object.reload
          expect(media_object.title).to eq old_title+'new'
        end
        it "should add a masterfile to a mediaobject" do
          put 'json_update', format: 'json', id: media_object.pid, files: [masterfile], collection_id: media_object.collection_id
          expect(JSON.parse(response.body)['id'].class).to eq String
          expect(JSON.parse(response.body)).not_to include('errors')
          media_object.reload
          expect(media_object.parts.count).to eq 2
        end
        it "should return 404 if media object doesn't exist" do
          allow_any_instance_of(MediaObject).to receive(:save).and_return false
          put 'json_update', format: 'json', id: 'avalon:doesnt_exist', fields: {}, collection_id: media_object.collection_id
          expect(response.status).to eq(404)
        end
        it "should return 422 if media object update failed" do
          allow_any_instance_of(MediaObject).to receive(:save).and_return false
          put 'json_update', format: 'json', id: media_object.pid, fields: {}, collection_id: media_object.collection_id
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)).to include('errors')
          expect(JSON.parse(response.body)["errors"].class).to eq Array
          expect(JSON.parse(response.body)["errors"].first.class).to eq String
        end
      end
    end
  end

  describe "#new" do
    let!(:collection) { FactoryGirl.create(:collection) }

    it "should not let manager of other collections create an item in this collection" do
      skip
    end

    context "Default permissions should be applied" do
      it "should be editable by the creator" do
        login_user collection.managers.first
        expect { get 'new', collection_id: collection.pid }.to change { MediaObject.count }
        pid = MediaObject.all.last.pid
        expect(response).to redirect_to(edit_media_object_path(id: pid))
      end

      it "should copy default permissions from its owning collection" do
        login_user collection.depositors.first

        get 'new', collection_id: collection.pid

        #MediaObject.all.last.edit_users.should include(collection.managers)
        #MediaObject.all.last.edit_users.should include(collection.depositors)
      end
    end

  end

  describe "#edit" do
    let!(:media_object) { FactoryGirl.create(:media_object) }

    it "should redirect to first workflow step if authorized to edit" do
       login_user media_object.collection.managers.first

       get 'edit', id: media_object.pid
       expect(response).to be_success
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
        get :edit, {id: media_object.pid, step: 'resource-description'}
        expect(response.response_code).to eq(200)
      end
    end

    context "Persisting Permalinks" do
      before(:each) { login_user mo.collection.managers.first }
      context "Persisting Permalinks on unpublished mediaobject" do
        subject(:mo) { media_object }
        it "should persist new permalink on unpublished media_object" do
          expect { put 'update', id: mo.pid, step: 'resource-description',
                   media_object: { permalink: 'newpermalink', title: 'newtitle',
                                   creator: 'newcreator', date_issued: 'newdateissued' }}
            .to change { MediaObject.find(mo.pid).permalink }
            .to('newpermalink')
        end
        it "should persist new permalink on unpublished media_object part" do
          part1 = FactoryGirl.create(:master_file, mediaobject: mo)
          expect {put 'update', id: mo.pid, step: 'file-upload',
                  parts: { part1.pid => { permalink: 'newpermalinkpart' }}}
            .to change { MasterFile.find(part1.pid).permalink }
            .to('newpermalinkpart')
        end
      end
      context "Persisting Permalinks on published mediaobject" do
        subject(:mo) { FactoryGirl.create(:published_media_object, permalink: 'oldpermalink') }
        it "should persist updated permalink on published media_object" do
          expect { put 'update', id: mo.pid, step: 'resource-description',
                   media_object: { permalink: 'newpermalink', title: mo.title,
                                   creator: mo.creator, date_issued: mo.date_issued }}
            .to change { MediaObject.find(mo.pid).permalink }
            .to('newpermalink')
        end
        it "should persist updated permalink on published media_object part" do
          part1 = FactoryGirl.create(:master_file, permalink: 'oldpermalinkpart1', mediaobject: mo)
          expect { put 'update', id: mo.pid, step: 'file-upload',
                   parts: { part1.pid => { permalink: 'newpermalinkpart' }}}
            .to change { MasterFile.find(part1.pid).permalink }
            .to('newpermalinkpart')
        end
      end
    end
  end

  describe "#index" do
    let!(:media_object) { FactoryGirl.create(:published_media_object, visibility: 'public') }
    subject(:json) { JSON.parse(response.body) }

    it "should return list of media_objects" do
      request.headers['Avalon-Api-Key'] = 'secret_token'
      get 'index', format:'json'
      expect(json.count).to eq(1)
      expect(json.first['id']).to eq(media_object.pid)
      expect(json.first['title']).to eq(media_object.title)
      expect(json.first['collection']).to eq(media_object.collection.name)
      expect(json.first['main_contributors']).to eq(media_object.creator)
      expect(json.first['publication_date']).to eq(media_object.date_created)
      expect(json.first['published_by']).to eq(media_object.avalon_publisher)
      expect(json.first['published']).to eq(media_object.published?)
      expect(json.first['summary']).to eq(media_object.abstract)
    end
  end

  describe 'pagination' do
      let(:collection) { FactoryGirl.create(:collection) }
      subject(:json) { JSON.parse(response.body) }
      before do
        5.times { FactoryGirl.create(:published_media_object, visibility: 'public', collection: collection) }
        request.headers['Avalon-Api-Key'] = 'secret_token'
        get 'index', format:'json', per_page: '2'
      end
      it 'should paginate' do
        expect(json.count).to eq(2)
        expect(response.headers['Per-Page']).to eq('2')
        expect(response.headers['Total']).to eq('5')
      end
  end

  describe "#show" do
    let!(:media_object) { FactoryGirl.create(:published_media_object, visibility: 'public') }

    context "Known items should be retrievable" do
      it "should be accesible by its PID" do
        get :show, id: media_object.pid
        expect(response.response_code).to eq(200)
      end

      it "should return an error if the PID does not exist" do
        expect(MediaObject).to receive(:find).with('no-such-object') { raise ActiveFedora::ObjectNotFoundError }
        get :show, id: 'no-such-object'
        expect(response.response_code).to eq(404)
      end

      it "should be available to a manager when unpublished" do
        login_user media_object.collection.managers.first
        get 'show', id: media_object.pid
        expect(response).not_to redirect_to new_user_session_path
      end

      it "should provide a JSON stream description to the client" do
        master_file = FactoryGirl.create(:master_file)
        master_file.mediaobject = media_object
        master_file.save

        mopid = media_object.pid
        media_object = MediaObject.find(mopid)

        media_object.parts.collect { |part|
          get 'show', id: media_object.pid, format: 'js', content: part.pid
          json_obj = JSON.parse(response.body)
          expect(json_obj['is_video']).to eq(part.is_video?)
        }
      end
    end

    context "Conditional Share partials should be rendered" do
      context "Normal login" do
        it "administrators: should include lti, embed, and share" do
          login_as(:administrator)
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to render_template(:_lti_url)
        end
        it "managers: should include lti, embed, and share" do
          login_user media_object.collection.managers.first
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to render_template(:_lti_url)
        end
        it "editors: should include lti, embed, and share" do
          login_user media_object.collection.editors.first
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to render_template(:_lti_url)
        end
        it "others: should include embed and share and NOT lti" do
          login_as(:user)
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to_not render_template(:_lti_url)
        end
      end
      context "LTI login" do
        it "administrators/managers/editors: should include lti, embed, and share" do
          user = login_lti 'administrator'
          lti_group = @controller.user_session[:virtual_groups].first
          mo = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to render_template(:_lti_url)
        end
        it "others: should include only lti" do
          user = login_lti 'student'
          lti_group = @controller.user_session[:virtual_groups].first
          mo = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
          get :show, id: media_object.pid
          expect(response).to_not render_template(:_share_resource)
          expect(response).to_not render_template(:_embed_resource)
          expect(response).to render_template(:_lti_url)
        end
      end
      context "No share tabs rendered" do
        it "should not render Share button" do
          allow(@controller).to receive(:evaluate_if_unless_configuration).and_return false
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
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to_not render_template(:_lti_url)
        end
      end
    end

    context "correctly handle unfound streams/sections" do
      subject(:mo){FactoryGirl.create(:media_object_with_master_file)}
      before do
        mo.save(validate: false)
        login_user mo.collection.managers.first
      end
      it "redirects to first stream when currentStream is nil" do
        expect(get 'show', id: mo.pid, content: 'foo').to redirect_to(media_object_path(id: mo.pid))
      end
      it "responds with 404 when non-existant section is requested" do
        get 'show', id: mo.pid, part: 100
        expect(response.code).to eq('404')
      end
    end

    describe 'Redirect back to media object after sign in' do
      let(:media_object){ FactoryGirl.create(:media_object, visibility: 'private') }

      context 'Before sign in' do
        it 'persists the current url on the session' do
          get 'show', id: media_object.pid
          expect(session[:previous_url]).to eql media_object_path(media_object)
        end
      end

      context 'After sign in' do
        before do
          @user = FactoryGirl.create(:user)
          @media_object = FactoryGirl.create(:media_object, visibility: 'private', read_users: [@user.username] )
        end
        it 'redirects to the previous url' do
        end
        it 'removes the previous url from the session' do
        end
      end
    end

    context "Items should not be available to unauthorized users" do
      it "should redirect to sign in when not logged in and item is unpublished" do
        media_object.publish!(nil)
        expect(media_object).not_to be_published
        get 'show', id: media_object.pid
        expect(response).to redirect_to new_user_session_path
      end

      it "should redirect to home page when logged in and item is unpublished" do
        media_object.publish!(nil)
        expect(media_object).not_to be_published
        login_as :user
        get 'show', id: media_object.pid
        expect(response).to redirect_to root_path
      end
    end

    context "with json format" do
      subject(:json) { JSON.parse(response.body) }
      let!(:media_object) { FactoryGirl.create(:media_object) }

      before do
  request.headers['Avalon-Api-Key'] = 'secret_token'
      end

      it "should return json for specific media_object" do
        get 'show', id: media_object.pid, format:'json'
        expect(json['id']).to eq(media_object.pid)
        expect(json['title']).to eq(media_object.title)
        expect(json['collection']).to eq(media_object.collection.name)
        expect(json['main_contributors']).to eq(media_object.creator)
        expect(json['publication_date']).to eq(media_object.date_created)
        expect(json['published_by']).to eq(media_object.avalon_publisher)
        expect(json['published']).to eq(media_object.published?)
        expect(json['summary']).to eq(media_object.abstract)
      end

      it "should return 404 if requested media_object not present" do
        login_as(:administrator)
        get 'show', id: 'avalon:doesnt_exist', format: 'json'
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)["errors"].class).to eq Array
        expect(JSON.parse(response.body)["errors"].first.class).to eq String
      end
    end

  end

  describe "#destroy" do
    let!(:collection) { FactoryGirl.create(:collection) }
    before(:each) do
      login_user collection.managers.first
    end

    it "should remove the MediaObject and MasterFiles from the system" do
      media_object = FactoryGirl.create(:media_object_with_master_file, collection: collection)
      delete :destroy, id: media_object.pid
      expect(flash[:notice]).to include("success")
      expect(MediaObject.exists?(media_object.pid)).to be_falsey
      expect(MasterFile.exists?(media_object.parts.first.id)).to be_falsey
    end

    it "should fail when id doesn't exist" do
      delete :destroy, id: 'avalon:this-pid-is-fake'
      expect(response.code).to eq '404'
    end

    it "should remove multiple items" do
      media_objects = []
      3.times { media_objects << FactoryGirl.create(:media_object, collection: collection) }
      delete :destroy, id: media_objects.map(&:id)
      expect(flash[:notice]).to include('3 media objects')
      media_objects.each {|mo| expect(MediaObject.exists?(mo.pid)).to be_falsey }
    end
  end

  describe "#update_status" do
    let!(:collection) { FactoryGirl.create(:collection) }
    before(:each) do
      login_user collection.managers.first
      request.env["HTTP_REFERER"] = '/'
    end

    context 'publishing' do
      before(:each) do
        Permalink.on_generate { |obj| "http://example.edu/permalink" }
      end
      it 'publishes media object' do
  media_object = FactoryGirl.create(:media_object, collection: collection)
        get 'update_status', id: media_object.pid, status: 'publish'
        media_object.reload
        expect(media_object).to be_published
        expect(media_object.permalink).to be_present
      end

      it "should fail when id doesn't exist" do
  get 'update_status', id: 'avalon:this-pid-is-fake', status: 'publish'
  expect(response.code).to eq '404'
      end

      it "should publish multiple items" do
  media_objects = []
  3.times { media_objects << FactoryGirl.create(:media_object, collection: collection) }
        get 'update_status', id: media_objects.map(&:id), status: 'publish'
  expect(flash[:notice]).to include('3 media objects')
        media_objects.each do |mo|
          mo.reload
    expect(mo).to be_published
    expect(mo.permalink).to be_present
        end
      end
    end

    context 'unpublishing' do
      it 'unpublishes media object' do
        media_object = FactoryGirl.create(:published_media_object, collection: collection)
        get 'update_status', :id => media_object.pid, :status => 'unpublish'
        media_object.reload
        expect(media_object).not_to be_published
      end

      it "should fail when id doesn't exist" do
  get 'update_status', id: 'avalon:this-pid-is-fake', status: 'unpublish'
  expect(response.code).to eq '404'
      end

      it "should unpublish multiple items" do
  media_objects = []
  3.times { media_objects << FactoryGirl.create(:published_media_object, collection: collection) }
        get 'update_status', id: media_objects.map(&:id), status: 'unpublish'
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
      media_object = FactoryGirl.create(:published_media_object)
      user = FactoryGirl.create(:public)
      bookmark = Bookmark.create(document_id: media_object.pid, user_id: user.id)
      login_user media_object.collection.managers.first
      request.env["HTTP_REFERER"] = '/'
      expect {
        get 'update_status', id: media_object.pid, status: 'unpublish'
      }.to change { Bookmark.exists? bookmark }.from( true ).to( false )
    end
  end

  describe "#update" do
    it 'updates the order' do

      media_object = FactoryGirl.create(:media_object)
      media_object.parts << FactoryGirl.create(:master_file)
      media_object.parts << FactoryGirl.create(:master_file)
      master_file_pids = media_object.parts.map(&:id)
      media_object.section_pid = master_file_pids
      media_object.save( validate: false )

      login_user media_object.collection.managers.first

      put 'update', :id => media_object.pid, :masterfile_ids => master_file_pids.reverse, :step => 'structure'
      media_object.reload
      expect(media_object.section_pid).to eq master_file_pids.reverse
    end
    it 'sets the MIME type' do
      media_object = FactoryGirl.create(:media_object)
      media_object.parts << FactoryGirl.create(:master_file_with_derivative)
      media_object.section_pid = media_object.parts.map(&:id)
      media_object.set_media_types!
      media_object.save( validate: false )
      media_object.reload
      expect(media_object.descMetadata.media_type).to eq(["video/mp4"])
    end
  end

  describe "#show_progress" do
    it "should return information about the processing state of the media object's parts" do
      media_object =  FactoryGirl.create(:media_object_with_master_file)
      login_as 'administrator'
      get :show_progress, id: media_object.id, format: 'json'
      expect(JSON.parse(response.body)["overall"]).to_not be_empty
    end
    it "should return something even if the media object has no parts" do
      media_object = FactoryGirl.create(:media_object)
      login_as 'administrator'
      get :show_progress, id: media_object.id, format: 'json'
      expect(JSON.parse(response.body)["overall"]).to_not be_empty
    end
  end
end
