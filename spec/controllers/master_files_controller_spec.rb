# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

describe MasterFilesController do

  describe "#create" do
    let(:media_object) { FactoryGirl.create(:media_object) }
    # TODO: fill in the lets below with a legitimate values from mediainfo
    # let(:mediainfo_video) {  }
    # let(:mediainfo_audio) {  }

    before do
      # login_user media_object.collection.managers.first
      login_as :administrator
      disableCanCan!
      # allow_any_instance_of(MasterFile).to receive(:mediainfo).and_return(mediainfo_output)
    end

    context "must provide a container id" do
      it "fails if no container id provided" do
        request.env["HTTP_REFERER"] = "/"
        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')

        expect { post :create, Filedata: [file], original: 'any' }.not_to change { MasterFile.count }
      end
    end

    context "must provide a valid media object" do
      before do
        media_object.title = nil
        media_object.date_issued = nil
        media_object.workflow.last_completed_step = 'file-upload'
        media_object.save(validate: false)
      end

      it "fails if parent media object is invalid" do
        request.env["HTTP_REFERER"] = "/"
        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        expect(media_object.valid?).to be_falsey
        expect { post :create, Filedata: [file], original: 'any', container_id: media_object.id }.not_to change { MasterFile.count }
      end
    end

    context "cannot upload a file over the defined limit" do
      it "provides a warning about the file size" do
        request.env["HTTP_REFERER"] = "/"

        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        allow(file).to receive(:size).and_return(MasterFile::MAXIMUM_UPLOAD_SIZE + 2 ^ 21)

        expect { post :create, Filedata: [file], original: 'any', container_id: media_object.id }.not_to change { MasterFile.count }

        expect(flash[:error]).not_to be_nil
      end
    end

    context "cannot upload a file with a non-ascii character in the filename" do
      it "provides a warning about the invalid filename" do
        request.env["HTTP_REFERER"] = "/"

        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        allow(file).to receive(:original_filename).and_return("videoshort_é.mp4")

        expect { post :create, Filedata: [file], original: 'any', container_id: media_object.id }.not_to change { MasterFile.count }

        expect(flash[:error]).not_to be_nil
      end
    end

    context "must be a valid MIME type" do
      it "recognizes a video format" do
        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        post :create, Filedata: [file], original: 'any', container_id: media_object.id

        master_file = media_object.reload.ordered_master_files.to_a.first
        expect(master_file.file_format).to eq "Moving image"

        expect(flash[:error]).to be_nil
      end

      it "recognizes an audio format" do
        file = fixture_file_upload('/jazz-performance.mp3', 'audio/mp3')
        post :create, Filedata: [file], original: 'any', container_id: media_object.id

        master_file = media_object.reload.ordered_master_files.to_a.first
        expect(master_file.file_format).to eq "Sound"
      end

      it "rejects non audio/video format" do
        request.env["HTTP_REFERER"] = "/"

        file = fixture_file_upload('/public-domain-book.txt', 'application/json')

        expect { post :create, Filedata: [file], original: 'any', container_id: media_object.id }.not_to change { MasterFile.count }

        expect(flash[:error]).not_to be_nil
      end

      it "recognizes audio/video based on extension when MIMETYPE is of unknown format" do
        file = fixture_file_upload('/videoshort.mp4', 'application/octet-stream')

        post :create, Filedata: [file], original: 'any', container_id: media_object.id
        master_file = MasterFile.all.last
        expect(master_file.file_format).to eq "Moving image"

        expect(flash[:error]).to be_nil
      end
    end

    # rubocop:disable RSpec/ExampleLength
    context "processes a file successfully" do
      it "associates with a MediaObject" do
        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        # Work-around for a Rails bug
        class << file
          attr_reader :tempfile
        end

        post :create, Filedata: [file], original: 'any', container_id: media_object.id

        master_file = MasterFile.all.last
        expect(media_object.reload.ordered_master_files.to_a).to include master_file
        expect(master_file.media_object.id).to eq(media_object.id)

        expect(flash[:error]).to be_nil
      end

      it "associates a dropbox file" do
        selected_files = { '0' => { url: 'file://' + Rails.root.join('spec', 'fixtures', 'videoshort.mp4').to_s, filename: 'videoshort.mp4', filesize: '100000' } }
        post :create, selected_files: selected_files, original: 'any', container_id: media_object.id

        master_file = MasterFile.all.last
        media_object.reload
        expect(media_object.ordered_master_files.to_a).to include master_file
        expect(master_file.media_object.id).to eq(media_object.id)

        expect(flash[:error]).to be_nil
      end

      it "associates a dropbox file that has a space in its name" do
        selected_files = { '0' => { url: 'file://' + Rails.root.join('spec', 'fixtures', 'video short.mp4').to_s, filename: 'video short.mp4', filesize: '100000' } }
        post :create, selected_files: selected_files, original: 'any', container_id: media_object.id

        master_file = MasterFile.all.last
        media_object.reload
        expect(media_object.ordered_master_files.to_a).to include master_file
        expect(master_file.media_object.id).to eq(media_object.id)

        expect(flash[:error]).to be_nil
      end

      it "does not fail when associating with a published media_object" do
        media_object = FactoryGirl.create(:published_media_object)
        login_user media_object.collection.managers.first
        file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        # Work-around for a Rails bug
        class << file
          attr_reader :tempfile
        end

        post :create, Filedata: [file], original: 'any', container_id: media_object.id

        master_file = MasterFile.all.last
        expect(media_object.reload.ordered_master_files.to_a).to include master_file
        expect(master_file.media_object.id).to eq(media_object.id)

        expect(flash[:error]).to be_nil
      end
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "#destroy" do
    let!(:master_file) { FactoryGirl.create(:master_file, :with_media_object) }

    it "deletes a master file as administrator" do
      login_as :administrator
      expect(controller.current_ability.can?(:destroy, master_file)).to be_truthy
      expect { post :destroy, id: master_file.id }.to change { MasterFile.count }.by(-1)
      expect(master_file.media_object.reload.ordered_master_files.to_a).not_to include master_file
    end

    it "deletes a master file as manager of owning collection" do
      login_user master_file.media_object.collection.managers.first
      expect(controller.current_ability.can?(:destroy, master_file)).to be_truthy
      expect { post(:destroy, id: master_file.id) }.to change { MasterFile.count }.by(-1)
      expect(master_file.media_object.reload.ordered_master_files.to_a).not_to include master_file
    end

    it "redirects with a flash warning for end users" do
      login_as :user
      expect(controller.current_ability.can?(:destroy, master_file)).to be_falsey
      expect(post(:destroy, id: master_file.id)).to redirect_to(root_path)
      expect(flash[:notice]).not_to be_empty
    end
  end

  describe "#show" do
    let(:master_file) { FactoryGirl.create(:master_file, :with_media_object) }

    it "redirects you to the media object page with the correct section" do
      get :show, id: master_file.id, t: '10'
      expect(response).to redirect_to("#{id_section_media_object_path(master_file.media_object.id, master_file.id)}?t=10")
    end

    context 'with fedora 3 pid' do
      let!(:master_file) { FactoryGirl.create(:master_file, identifier: [fedora3_pid]) }
      let(:fedora3_pid) { 'avalon:1234' }

      it "redirects" do
        expect(get(:show, id: fedora3_pid)).to redirect_to(master_file_url(master_file.id))
      end
    end
  end

  describe "#embed" do
    let!(:master_file) { FactoryGirl.create(:master_file) }
    let(:media_object) do
      instance_double('MediaObject', title: 'Media Object', id: 'avalon:1234',
                                     ordered_master_files: [master_file], master_file_ids: [master_file.id])
    end

    render_views

    before do
      allow_any_instance_of(MasterFile).to receive(:media_object).and_return(media_object)
      allow_any_instance_of(MasterFile).to receive(:media_object_id).and_return(media_object.id)
      disableCanCan!
    end

    it "renders the embed layout" do
      expect(get(:embed, id: master_file.id)).to render_template(layout: 'embed')
    end

    it "renders the Google Analytics partial" do
      expect(get(:embed, id: master_file.id )).to render_template('modules/_google_analytics')
    end

    context 'with fedora 3 pid' do
      let!(:master_file) { FactoryGirl.create(:master_file, identifier: [fedora3_pid]) }
      let(:fedora3_pid) { 'avalon:1234' }

      it "redirects" do
        expect(get(:embed, id: fedora3_pid)).to redirect_to(embed_master_file_url(master_file.id))
      end
    end
  end

  describe "#set_frame" do
    subject(:mf) { FactoryGirl.create(:master_file, :with_thumbnail, :with_media_object) }

    it "redirects to sign in when not logged in" do
      expect(get(:set_frame, id: mf.id)).to redirect_to new_user_session_path
    end

    it "redirects to home when logged in and not authorized" do
      login_as :user
      expect(get(:set_frame, id: mf.id)).to redirect_to root_path
    end

    context "authorized" do
      before { disableCanCan! }

      it "redirects to edit_media_object" do
        expect(get(:set_frame, id: mf.id, type: 'thumbnail', offset: '10')).to redirect_to edit_media_object_path(mf.media_object_id, step: 'file-upload')
      end

      it "returns thumbnail" do
        expect_any_instance_of(MasterFile).to receive(:extract_still) { 'fake image content' }

        get :set_frame, format: 'jpeg', id: mf.id, type: 'thumbnail', offset: '10'
        expect(response.body).to eq('fake image content')
        expect(response.headers['Content-Type']).to eq('image/jpeg')
      end
    end
  end

  describe "#get_frame" do
    subject(:mf) { FactoryGirl.create(:master_file, :with_thumbnail, :with_media_object) }

    context "not authorized" do
      it "redirects to sign in when not logged in" do
        expect(get(:get_frame, id: mf.id)).to redirect_to new_user_session_path
      end

      it "redirects to home when logged in and not authorized" do
        login_as :user
        expect(get(:get_frame, id: mf.id)).to redirect_to root_path
      end

    end
    context "authorized" do
      before { disableCanCan! }

      it "returns thumbnail" do
        get :get_frame, id: mf.id, type: 'thumbnail', size: 'bar'
        expect(response.body).to eq('fake image content')
        expect(response.headers['Content-Type']).to eq('image/jpeg')
      end

      it "returns offset thumbnail" do
        expect_any_instance_of(MasterFile).to receive(:extract_still) { 'fake image content' }
        get :get_frame, id: mf.id, type: 'thumbnail', size: 'bar', offset: '1'
        expect(response.body).to eq('fake image content')
        expect(response.headers['Content-Type']).to eq('image/jpeg')
      end
    end
  end

  # rubocop:disable RSpec/ExampleLength
  describe "#attach_structure" do
    let(:master_file) { FactoryGirl.create(:master_file, :with_media_object) }
    let(:file) { fixture_file_upload('/structure.xml', 'text/xml') }

    before do
      disableCanCan!
      # populate the structuralMetadata datastream with an uploaded xml file
      post 'attach_structure', master_file: { structure: file }, id: master_file.id
      master_file.reload
    end

    it "populates structuralMetadata datastream with xml" do
      expect(master_file.structuralMetadata.xpath('//Item').length).to be(1)
      expect(master_file.structuralMetadata.valid?).to be true
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_nil
    end

    it "removes contents of structuralMetadata" do
      # remove the contents of the datastream
      post 'attach_structure', id: master_file.id
      master_file.reload
      # expect(master_file.structuralMetadata.new?).to be true
      expect(master_file.structuralMetadata.content.empty?).to be true
      expect(master_file.structuralMetadata.valid?).to be false
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_nil
    end

    context "with invalid XML file" do
      let(:file) { fixture_file_upload('/7763100.xml', 'text/xml') }

      it "gracefully handles an invalid file" do
        expect(master_file.structuralMetadata.content.nil?).to be_truthy
        expect(master_file.structuralMetadata.valid?).to be false
        expect(flash[:error]).not_to be_blank
        expect(flash[:notice]).to be_nil
      end
    end

    context "with invalid binary file" do
      let(:file) { fixture_file_upload('/videoshort.mp4', 'video/mp4') }

      it "gracefully handles an invalid file" do
        expect(master_file.structuralMetadata.content.nil?).to be_truthy
        expect(master_file.structuralMetadata.valid?).to be false
        expect(flash[:error]).not_to be_blank
        expect(flash[:notice]).to be_nil
      end
    end
  end
  describe "#attach_captions" do
    let(:master_file) { FactoryGirl.create(:master_file, :with_media_object) }

    before do
      disableCanCan!
    end

    it "populates captions datastream with text" do
      # populate the captions datastream with an uploaded vtt file
      file = fixture_file_upload('/captions.vtt', 'text/vtt')
      post 'attach_captions', master_file: { captions: file }, id: master_file.id
      master_file.reload
      expect(master_file.captions.has_content?).to be_truthy
      expect(master_file.captions.original_name).to eq('captions.vtt')
      expect(master_file.captions.mime_type).to eq('text/vtt')
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_nil
      expect(flash[:success]).not_to be_nil
    end

    it "works with bad mime types from the browser" do
      # populate the captions datastream with an uploaded vtt file
      file = fixture_file_upload('/captions.vtt', 'application/octet-stream')
      post 'attach_captions', master_file: { captions: file }, id: master_file.id
      master_file.reload
      expect(master_file.captions.has_content?).to be_truthy
      expect(master_file.captions.original_name).to eq('captions.vtt')
      expect(master_file.captions.mime_type).to eq('text/vtt')
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_nil
      expect(flash[:success]).not_to be_nil
    end

    it "removes contents of captions datastream" do
      # remove the contents of the datastream
      post 'attach_captions', id: master_file.id
      master_file.reload
      expect(master_file.captions.empty?).to be true
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_nil
      expect(flash[:success]).not_to be_nil
    end

    context "with invalid file" do
      let(:file) { fixture_file_upload('/videoshort.mp4', 'video/mp4') }

      it "gracefully handles an invalid file" do
        post 'attach_captions', master_file: { captions: file }, id: master_file.id
        master_file.reload
        expect(master_file.captions.has_content?).to be_falsey
        expect(flash[:error]).not_to be_blank
        expect(flash[:notice]).to be_nil
        expect(flash[:success]).to be_nil
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength

  describe "#captions" do
    let(:master_file) { FactoryGirl.create(:master_file, :with_media_object, :with_captions) }

    it "returns contents of the captions attached file" do
      login_as :administrator
      expect(get('captions', id: master_file.id)).to have_http_status(:ok)
    end
  end
end
