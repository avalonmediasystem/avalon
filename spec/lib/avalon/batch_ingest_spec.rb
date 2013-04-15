require 'spec_helper'
require 'avalon/dropbox'
require 'avalon/batch_ingest'

describe Avalon::Batch do
  before :all do
    # TODO : Locate all .processing files and delete them from the spec
    #        dropbox    
  end

  before :each do
    Avalon::DropboxService = Avalon::Dropbox.new 'spec/fixtures/dropbox'
    # Dirty hack is to remove the .processed files both before and after the
    # test. Need to look closer into the ideal timing for where this should take
    # place
    # this file is created to signify that the file has been processed
    # we need to remove it so can re-run the tests
    processed_status_file = 'spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx.processed'
    error_status_file = 'spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx.error'

    File.delete(processed_status_file) if File.exists?(processed_status_file)
    File.delete(error_status_file) if File.exists?(error_status_file)    
  end

  after :each do
    # this file is created to signify that the file has been processed
    # we need to remove it so can re-run the tests
    processed_status_file = 'spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx.processed'
    error_status_file = 'spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx.error'

    File.delete(processed_status_file) if File.exists?(processed_status_file)
    File.delete(error_status_file) if File.exists?(error_status_file)
    
    # this is a test environment, we don't want to kick off
    # generation jobs if possible
    MasterFile.any_instance.stub(:save).and_return(true)
   end

  it 'creates an ingest batch object' do
    Avalon::Batch.ingest
    IngestBatch.count.should == 1
  end

  it 'does not create an ingest batch object when there are zero packages' do
    Avalon::DropboxService.stub(:find_new_packages).and_return []
    Avalon::Batch.ingest
    IngestBatch.count.should == 0
  end

  it 'should have a column for file labels' do
    pending "[VOV-1347] Wait until implemented" 
  end

  it "should be able to default to public access" do
    pending "[VOV-1348] Wait until implemented"
  end

  it "should be able to default to specific groups" do
    pending "[VOV-1348] Wait until implemented"
  end
end
