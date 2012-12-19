require 'spec_helper'

describe 'Batch Ingest Email' do

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'has an error if media object has not been set' do
    ingest_batch = IngestBatch.create
    @email = BatchIngestMailer.status_email( ingest_batch.id  )
    @email.should have_body_text('There was an error.  It appears no files have been submitted')
  end

  it 'has an error if there are no media objects present' do
    @ingest_batch = IngestBatch.create( media_object_ids: [])
    @email = BatchIngestMailer.status_email( @ingest_batch.id )
    @email.should have_body_text('There was an error.  It appears no files have been submitted')
  end

  it 'shows the title of one media object' do
    load_fixture 'hydrant:video-segment'
    media_object = MediaObject.all.first
    ingest_batch = IngestBatch.create(media_object_ids: [media_object.id])
    @email = BatchIngestMailer.status_email(ingest_batch.id)
    @email.should have_body_text(media_object.title)
  end

  it 'has the status of a master file in a table row' do
    media_object = MediaObject.new
    media_object.update_datastream(:descMetadata, :title => 'Hiking')
    media_object.update_datastream(:descMetadata, :creator => 'Adam')
    media_object.update_datastream(:descMetadata, :date_created => 'January 2007')
    media_object.save

    master_file = MasterFile.new(pid:'changeme:20')
    master_file.status_code =  ['STOPPED']
    master_file.url = 'something/granite-mountain-hike.mov'
    master_file.percent_complete = ['100']

    media_object.parts << master_file
    
    media_object.save(validate: false)

    ingest_batch = IngestBatch.create( media_object_ids: [media_object.id])

    email = BatchIngestMailer.status_email( ingest_batch.id )
    page = Capybara::Node::Simple.new(email.body.to_s)
    base_selector = 'table > tbody > tr:nth-child(1) > '

    page.find(base_selector + 'td.master-file').should have_content(File.basename(master_file.url))
    page.find(base_selector + 'td.percent-complete').should have_content(master_file.percent_complete.first)
    page.find(base_selector + 'td.status-code').should have_content(master_file.status_code.first.downcase.titleize)
  end
end