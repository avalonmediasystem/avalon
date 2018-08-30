require 'rails_helper'

# MasterFile#working_file_path has been a source of problems since it was introduced in 6.4.3
# This spec file is meant to thoroughly test it in order to find any remaining bugs and to
# ensure the intended functionality doesn't get broken accidentally in the future.
#
# Need to test all of the possiblilites:
# batch ingest with single file
# batch ingest with single file skip transcoding
# batch ingest with pre-transcoded derivatives
# web upload
# web upload skip transcoding
# web dropbox upload
# web dropbox skip transcoding
# Repeat all of these with and without media path set.
#
# Pre-existing tests that are related (or duplicative)
# spec/models/master_file_spec.rb:262
# spec/models/master_file_spec.rb:500
# spec/lib/avalon/batch/entry_spec.rb:80
#
describe "MasterFile#working_file_path" do
  let(:master_file) { FactoryGirl.build(:master_file) }
  let(:media_object) { FactoryGirl.create(:media_object) }
  let(:workflow) { 'avalon' }

  context "with Settings.matterhorn.media_path set" do
    let(:media_path) { Dir.mktmpdir }

    around(:example) do |example|
      begin
        old_media_path = Settings.matterhorn.media_path
        Settings.matterhorn.media_path = media_path

        example.run

        Settings.matterhorn.media_path = old_media_path
      ensure
        FileUtils.remove_entry media_path
      end
    end

    describe '#calculate_working_file_path' do
      let(:path1) { MasterFile.calculate_working_file_path('/dropbox/coll1/video.mp4') }
      let(:path2) { MasterFile.calculate_working_file_path('/dropbox/coll2/video.mp4') }

      it 'returns a working file path' do
        expect(File.fnmatch("#{File.absolute_path(media_path)}/*/video.mp4", path1)).to be true
      end

      it 'creates a unique working_file_path for each file' do
        expect(path1).not_to eq path2
      end
    end

    it 'can recompute the working_file_path' do
      file = fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4')
      master_file.setContent(file)
      original_path = master_file.working_file_path
      master_file.save!
      new_path = MasterFile.find(master_file.id).working_file_path
      expect(original_path).to eq new_path
    end

    context "using web upload" do
      let(:file) { fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4') }
      let(:params) { { Filedata: [file], original: nil, workflow: workflow } }

      it 'sends the working_file_path to matterhorn' do
        MasterFileBuilder.build(media_object, params)
        master_file = media_object.reload.master_files.first
        expect(File.exists? master_file.working_file_path.first).to be true
        input = FileLocator.new(master_file.working_file_path.first).uri.to_s
        expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: workflow})
      end

      context "with skip transcoding" do
        let(:workflow) { 'skip_transcoding' }

        it 'sends the working_file_path to matterhorn' do
          MasterFileBuilder.build(media_object, params)
          master_file = media_object.reload.master_files.first
          expect(File.exists? master_file.working_file_path.first).to be true
          input = { "quality-high" => FileLocator.new(master_file.working_file_path.first).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end
    end

    context "using dropbox upload" do
      let(:file) { fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4') }
      let(:url) { Addressable::URI.convert_path(File.absolute_path(file.to_path)) }
      let(:params) { { selected_files: { "0" => { url: url, file_name: 'videoshort.mp4' } }, workflow: workflow } }

      it 'sends the working_file_path to matterhorn' do
        MasterFileBuilder.build(media_object, params)
        master_file = media_object.reload.master_files.first
        expect(File.exists? master_file.working_file_path.first).to be true
        input = FileLocator.new(master_file.working_file_path.first).uri.to_s
        expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: workflow})
      end

      context "with skip transcoding" do
        let(:workflow) { 'skip_transcoding' }

        it 'sends the working_file_path to matterhorn' do
          MasterFileBuilder.build(media_object, params)
          master_file = media_object.reload.master_files.first
          expect(File.exists? master_file.working_file_path.first).to be true
          input = { "quality-high" => FileLocator.new(master_file.working_file_path.first).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end
    end

    context "using batch ingest" do
      let(:file) { fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4') }
      let(:collection) { FactoryGirl.build(:collection) }
      let(:entry_fields) { { title: Faker::Lorem.sentence, date_issued: "#{DateTime.now.strftime('%F')}" } }
      let(:entry_files) { [{ file: File.absolute_path(file), skip_transcoding: false }] }
      let(:entry_opts) { {user_key: 'archivist1@example.org', collection: collection} }
      let(:entry) { Avalon::Batch::Entry.new(entry_fields, entry_files, entry_opts, nil, nil) }

      before do
        allow(entry).to receive(:media_object).and_return(media_object)
      end

      it 'sends the working_file_path to matterhorn' do
        entry.process!
        master_file = media_object.reload.master_files.first
        expect(File.exists? master_file.working_file_path.first).to be true
        input = FileLocator.new(master_file.working_file_path.first).uri.to_s
        expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: workflow})
      end

      context 'with skip transcoding' do
        let(:entry_files) { [{ file: File.absolute_path(file), skip_transcoding: true }] }

        it 'sends the working_file_path to matterhorn' do
          entry.process!
          master_file = media_object.reload.master_files.first
          expect(File.exists? master_file.working_file_path.first).to be true
          input = { "quality-high" => FileLocator.new(master_file.working_file_path.first).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end

      context 'with pre-transcoded derivatives' do
        let(:filename) {File.join(Rails.root, "spec/fixtures/videoshort.mp4")}
        %w(low medium high).each do |quality|
          let("filename_#{quality}".to_sym) {File.join(Rails.root, "spec/fixtures/videoshort.#{quality}.mp4")}
        end
        let(:derivative_paths) {[filename_low, filename_medium, filename_high]}
        let(:derivative_hash) {{'quality-low' => File.new(filename_low), 'quality-medium' => File.new(filename_medium), 'quality-high' => File.new(filename_high)}}

        let(:entry_files) { [{ file: filename, skip_transcoding: true }] }

        let(:original_file_locator) { instance_double("FileLocator") }
        before do
          allow(FileLocator).to receive(:new).and_call_original
          allow(FileLocator).to receive(:new).with(filename).and_return(original_file_locator)
          allow(original_file_locator).to receive(:exist?).and_return(false)
        end

        # All derivatives are copied to a working path
        # TODO: Ensure all working file copies are cleaned up by the background job
        it 'sends the working_file_path to matterhorn' do
          entry.process!
          master_file = media_object.reload.master_files.first
          working_file_path_high = master_file.working_file_path.find { |file| file.include? "high" }
          working_file_path_medium = master_file.working_file_path.find { |file| file.include? "medium" }
          working_file_path_low = master_file.working_file_path.find { |file| file.include? "low" }

          [working_file_path_high, working_file_path_medium, working_file_path_low].each do |file|
            expect(File.exists? file).to be true
          end
          input = { "quality-high" => FileLocator.new(working_file_path_high).uri.to_s,
                    "quality-medium" => FileLocator.new(working_file_path_medium).uri.to_s,
                    "quality-low" => FileLocator.new(working_file_path_low).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end
    end
  end

  context "without Settings.matterhorn.media_path set" do
    it 'returns blank' do
      expect(master_file.working_file_path).to be_blank
    end

    context "using web upload" do
      let(:file) { fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4') }
      let(:params) { { Filedata: [file], original: nil, workflow: workflow } }

      it 'sends the file_location to matterhorn' do
        MasterFileBuilder.build(media_object, params)
        master_file = media_object.reload.master_files.first
        input = FileLocator.new(master_file.file_location).uri.to_s
        expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: workflow})
      end

      context "with skip transcoding" do
        let(:workflow) { 'skip_transcoding' }

        it 'sends the file_location to matterhorn' do
          MasterFileBuilder.build(media_object, params)
          master_file = media_object.reload.master_files.first
          input = { "quality-high" => FileLocator.new(master_file.file_location).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end
    end

    context "using dropbox upload" do
      let(:file) { fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4') }
      let(:url) { Addressable::URI.convert_path(File.absolute_path(file.to_path)) }
      let(:params) { { selected_files: { "0" => { url: url, file_name: 'videoshort.mp4' } }, workflow: workflow } }

      it 'sends the file_location to matterhorn' do
        MasterFileBuilder.build(media_object, params)
        master_file = media_object.reload.master_files.first
        input = FileLocator.new(master_file.file_location).uri.to_s
        expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: workflow})
      end

      context "with skip transcoding" do
        let(:workflow) { 'skip_transcoding' }

        it 'sends the file_location to matterhorn' do
          MasterFileBuilder.build(media_object, params)
          master_file = media_object.reload.master_files.first
          input = { "quality-high" => FileLocator.new(master_file.file_location).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end
    end

    context "using batch ingest" do
      let(:file) { fixture_file_upload('spec/fixtures/videoshort.mp4', 'video/mp4') }
      let(:collection) { FactoryGirl.build(:collection) }
      let(:entry_fields) { { title: Faker::Lorem.sentence, date_issued: "#{DateTime.now.strftime('%F')}" } }
      let(:entry_files) { [{ file: File.absolute_path(file), skip_transcoding: false }] }
      let(:entry_opts) { {user_key: 'archivist1@example.org', collection: collection} }
      let(:entry) { Avalon::Batch::Entry.new(entry_fields, entry_files, entry_opts, nil, nil) }

      before do
        allow(entry).to receive(:media_object).and_return(media_object)
      end

      it 'sends the file_location to matterhorn' do
        entry.process!
        master_file = media_object.reload.master_files.first
        input = FileLocator.new(master_file.file_location).uri.to_s
        expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: workflow})
      end

      context 'with skip transcoding' do
        let(:entry_files) { [{ file: File.absolute_path(file), skip_transcoding: true }] }

        it 'sends the file_location to matterhorn' do
          entry.process!
          master_file = media_object.reload.master_files.first
          input = { "quality-high" => FileLocator.new(master_file.file_location).uri.to_s }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end

      context 'with pre-transcoded derivatives' do
        let(:filename) {File.join(Rails.root, "spec/fixtures/videoshort.mp4")}
        %w(low medium high).each do |quality|
          let("filename_#{quality}".to_sym) {File.join(Rails.root, "spec/fixtures/videoshort.#{quality}.mp4")}
        end
        let(:derivative_paths) {[filename_low, filename_medium, filename_high]}
        let(:derivative_hash) {{'quality-low' => File.new(filename_low), 'quality-medium' => File.new(filename_medium), 'quality-high' => File.new(filename_high)}}

        let(:entry_files) { [{ file: filename, skip_transcoding: true }] }

        let(:original_file_locator) { instance_double("FileLocator") }
        before do
          allow(FileLocator).to receive(:new).and_call_original
          allow(FileLocator).to receive(:new).with(filename).and_return(original_file_locator)
          allow(original_file_locator).to receive(:exist?).and_return(false)
        end

        it 'sends the derivative locations to matterhorn' do
          entry.process!
          master_file = media_object.reload.master_files.first
          input = {'quality-low' => Addressable::URI.convert_path(File.absolute_path(filename_low)).to_s,
                   'quality-medium' => Addressable::URI.convert_path(File.absolute_path(filename_medium)).to_s,
                   'quality-high' => Addressable::URI.convert_path(File.absolute_path(filename_high)).to_s
                  }
          expect(ActiveEncodeJob::Create).to have_been_enqueued.with(master_file.id, input, {preset: 'avalon-skip-transcoding'})
        end
      end
    end
  end
end
