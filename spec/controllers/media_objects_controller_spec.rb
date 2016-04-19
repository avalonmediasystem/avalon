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
    let!(:captions) {File.read(File.join(testdir, 'dropbox/example_batch_ingest/assets/sheephead_mountain.mov.vtt'))}
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
        date_digitized: "2015-12-31",
        workflow_name: "avalon",
        percent_complete: "100.0",
        percent_succeeded: "100.0",
        percent_failed: "0",
        status_code: "COMPLETED",
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
          expect(new_media_object.avalon_resource_type).to eq ['moving image']
          expect(new_media_object.parts.first.date_digitized).to eq('2015-12-31T00:00:00Z')
          expect(new_media_object.parts.first.DC.identifier).to include('40000000045312')
          expect(new_media_object.parts.first.structuralMetadata.has_content?).to be_truthy
          expect(new_media_object.parts.first.captions.has_content?).to be_truthy
          expect(new_media_object.parts.first.captions.label).to eq('ingest.api')
          expect(new_media_object.parts.first.captions.mimeType).to eq('text/vtt')
          expect(new_media_object.parts.first.derivatives.count).to eq(2)
          expect(new_media_object.parts.first.derivatives.first.location_url).to eq(absolute_location)          
          expect(new_media_object.workflow.last_completed_step).to eq([HYDRANT_STEPS.last.step])
       end
        it "should create a new published mediaobject" do
          media_object = FactoryGirl.create(:multiple_entries)
          fields = media_object.attributes.select {|k,v| descMetadata_fields.include? k.to_sym }
          post 'create', format: 'json', fields: fields, files: [masterfile], collection_id: collection.pid, publish: true
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.published?).to be_truthy
          expect(new_media_object.workflow.last_completed_step).to eq([HYDRANT_STEPS.last.step])
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
        it "should create a new mediaobject with supplied fields when bib import fails" do
          Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
          FakeWeb.register_uri :get, sru_url, body: nil
          media_object = FactoryGirl.create(:media_object)
          fields = media_object.attributes.select {|k,v| descMetadata_fields.include? k.to_sym }
          fields = fields.merge({ bibliographic_id: bib_id })
          post 'create', format: 'json', import_bib_record: true, fields: fields, files: [masterfile], collection_id: collection.pid
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.bibliographic_id).to eq(['local', bib_id])
          expect(new_media_object.title).to eq media_object.title
          expect(new_media_object.creator).to eq [] #creator no longer required, so supplied value won't be used
          expect(new_media_object.date_issued).to eq media_object.date_issued
        end
        it "should create a new mediaobject, removing invalid data for non-required fields" do
          media_object = FactoryGirl.create(:multiple_entries)
          fields = media_object.attributes.select {|k,v| descMetadata_fields.include? k.to_sym }
          fields[:language] = ['???']
          fields[:related_item_url] = ['???']
          fields[:note] = ['note']
          fields[:note_type] = ['???']
          fields[:date_created] = '???'
          fields[:copyright_date] = '???'
          post 'create', format: 'json', fields: fields, files: [masterfile], collection_id: collection.pid
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.title).to eq media_object.title
          expect(new_media_object.language).to eq []
          expect(new_media_object.related_item_url).to eq []
          expect(new_media_object.note).to eq nil
          expect(new_media_object.date_created).to eq nil
          expect(new_media_object.copyright_date).to eq nil
        end
        it "should merge supplied other identifiers after bib import" do
          Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
          FakeWeb.register_uri :get, sru_url, body: sru_response
          fields = { bibliographic_id: bib_id, other_identifier_type: ['other'], other_identifier: ['12345'] }
          post 'create', format: 'json', import_bib_record: true, fields: fields, files: [masterfile], collection_id: collection.pid
          expect(response.status).to eq(200)
          new_media_object = MediaObject.find(JSON.parse(response.body)['id'])
          expect(new_media_object.bibliographic_id).to eq(['local', bib_id])
          expect(new_media_object.other_identifier.find {|id_pair| id_pair[0] == 'other'}).not_to be nil
          expect(new_media_object.other_identifier.find {|id_pair| id_pair[0] == 'other'}[1]).to eq('12345')
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
        it "should delete existing masterfiles and add a new masterfile to a mediaobject" do
          put 'json_update', format: 'json', id: media_object.pid, files: [masterfile], collection_id: media_object.collection_id, replace_masterfiles: true
          expect(JSON.parse(response.body)['id'].class).to eq String
          expect(JSON.parse(response.body)).not_to include('errors')
          media_object.reload
          expect(media_object.parts.count).to eq 1
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
    
    context "Hidden Items" do
      subject(:mo) { FactoryGirl.create(:media_object_with_completed_workflow, hidden: true) }
      let!(:user) { Faker::Internet.email }
      before(:each) { login_user mo.collection.managers.first }

      it "should retain the hidden status of an object when other access control settings change" do
        expect { put 'update', id: mo.pid, step: 'access-control', donot_advance: 'true', 
                 add_user: user, add_user_display: user, submit_add_user: 'Add' }
          .not_to change { MediaObject.find(mo.pid).hidden? }
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
    context "Test lease access control" do
      let!(:media_object) { FactoryGirl.create(:published_media_object, visibility: 'private') }
      let!(:user) { FactoryGirl.create(:user) }
      before :each do
        login_user user.username
      end
      it "should not be available to a user on an inactive lease" do
        media_object.governing_policies+=[Lease.create(begin_time: Date.today-2.day, end_time: Date.yesterday, read_users: [user.username])]
        media_object.save!
        get 'show', id: media_object.pid
        expect(response.response_code).not_to eq(200)
      end
      it "should be available to a user on an active lease" do
        media_object.governing_policies+=[Lease.create(begin_time: Date.yesterday, end_time: Date.tomorrow, read_users: [user.username])]
        media_object.save!
        get 'show', id: media_object.pid
        expect(response.response_code).to eq(200)
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
          login_lti 'administrator'
          lti_group = @controller.user_session[:virtual_groups].first
          FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
          get :show, id: media_object.pid
          expect(response).to render_template(:_share_resource)
          expect(response).to render_template(:_embed_resource)
          expect(response).to render_template(:_lti_url)
        end
        it "others: should include only lti" do
          login_lti 'student'
          lti_group = @controller.user_session[:virtual_groups].first
          FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
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
    before { Delayed::Worker.delay_jobs = false }
    after  { Delayed::Worker.delay_jobs = true  }

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
      2.times do
        mf = FactoryGirl.create(:master_file)
        mf.mediaobject = media_object
        mf.save
      end
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

    context 'large objects' do
      before(:each) do
        Permalink.on_generate { |obj| sleep(0.5); "http://example.edu/permalink" }
      end

      let!(:media_object) do
        mo = FactoryGirl.create(:published_media_object)
        10.times { FactoryGirl.create(:master_file_with_derivative, mediaobject: mo) }
        mo
      end
      
      it "should update all the labels" do
        login_user media_object.collection.managers.first
        part_params = {}
        media_object.parts_with_order.each_with_index { |mf,i| part_params[mf.pid] = { pid: mf.pid, label: "Part #{i}", permalink: '', poster_offset: '00:00:00.000' } }
        params = { id: media_object.pid, parts: part_params, save: 'Save', step: 'file-upload', donot_advance: 'true' }
        patch 'update', params
        media_object.reload
        media_object.parts_with_order.each_with_index do |mf,i|
          expect(mf.label).to eq "Part #{i}"
        end
      end
    end

    context "access controls" do
      let!(:media_object) { FactoryGirl.create(:media_object) }
      let!(:user) { Faker::Internet.email }
      let!(:group) { Faker::Lorem.word }
      let!(:classname) { Faker::Lorem.word }
      let!(:ipaddr) { Faker::Internet.ip_v4_address }
      before(:each) { login_user media_object.collection.managers.first }

      context "grant and revoke special read access" do
        it "grants and revokes special read access to users" do
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add' }.to change { media_object.reload.read_users }.from([]).to([user])
          expect {put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', remove_user: user, submit_remove_user: 'Remove' }.to change { media_object.reload.read_users }.from([user]).to([]) 
        end
        it "grants and revokes special read access to groups" do
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_group: group, submit_add_group: 'Add' }.to change { media_object.reload.read_groups }.from([]).to([group])
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', remove_group: group, submit_remove_group: 'Remove' }.to change { media_object.reload.read_groups }.from([group]).to([])
        end
        it "grants and revokes special read access to external groups" do
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_class: classname, submit_add_class: 'Add' }.to change { media_object.reload.read_groups }.from([]).to([classname])
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', remove_class: classname, submit_remove_class: 'Remove' }.to change { media_object.reload.read_groups }.from([classname]).to([])
        end
        it "grants and revokes special read access to ips" do
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_ipaddress: ipaddr, submit_add_ipaddress: 'Add' }.to change { media_object.reload.read_groups }.from([]).to([ipaddr])
          expect { put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', remove_ipaddress: ipaddr, submit_remove_ipaddress: 'Remove' }.to change { media_object.reload.read_groups }.from([ipaddr]).to([])
        end
      end

      context "grant and revoke time-based special read access" do
        it "should grant and revoke time-based access for users" do 
          expect {
            put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.yesterday, add_user_end: Date.tomorrow
            media_object.reload
          }.to change{media_object.governing_policies.count}.by(1)
          expect(media_object.governing_policies.last.class).to eq(Lease)
          lease_pid = media_object.reload.governing_policies.last.pid
          expect {
            put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', remove_lease: lease_pid
            media_object.reload
          }.to change{media_object.governing_policies.count}.by(-1)
        end
      end

      context "must validate lease date ranges" do
        it "should accept valid date range for lease" do
          expect { 
            put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.today, add_user_end: Date.tomorrow 
            media_object.reload
          }.to change{media_object.governing_policies.count}.by(1)
        end
        it "should reject reverse date range for lease" do
          expect { 
            put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.tomorrow, add_user_end: Date.today
            media_object.reload
          }.not_to change{media_object.governing_policies.count} 
        end
        it "should accept missing begin date and set it to today" do
          expect { 
            put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: '', add_user_end: Date.tomorrow
            media_object.reload
          }.to change{media_object.governing_policies.count}.by(1) 
          expect(media_object.governing_policies.last.begin_time).to eq(Date.today)
        end
        it "should reject missing end date" do
          expect { 
            put :update, id: media_object.id, step: 'access-control', donot_advance: 'true', add_user: user, submit_add_user: 'Add', add_user_begin: Date.tomorrow, add_user_end: ''
            media_object.reload
          }.not_to change{media_object.governing_policies.count} 
        end
      end
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

  describe "#set_session_quality" do
    it "should set the posted quality in the session" do
      login_as 'administrator'
      post :set_session_quality, quality: 'crazy_high'
      expect(@request.session[:quality]).to eq('crazy_high')
    end
  end
end
