# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
#require 'capybara/rspec'

describe 'Batch Ingest Email' do

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'has an error if media object has not been set' do
    ingest_batch = IngestBatch.create
    @email = IngestBatchMailer.status_email( ingest_batch.id  )
    @email.should have_body_text('There was an error.  It appears no files have been submitted')
  end

  it 'has an error if there are no media objects present' do
    @ingest_batch = IngestBatch.create( media_object_ids: [])
    @email = IngestBatchMailer.status_email( @ingest_batch.id )
    @email.should have_body_text('There was an error.  It appears no files have been submitted')
  end

  it 'shows the title of one media object' do
    load_fixture 'avalon:video-segment'
    media_object = MediaObject.all.first
    ingest_batch = IngestBatch.create(media_object_ids: [media_object.id])
    @email = IngestBatchMailer.status_email(ingest_batch.id)
    @email.should have_body_text(media_object.title)
  end

  it 'has the status of the master file in a first row' do
    media_object = MediaObject.new
    media_object.update_datastream(:descMetadata, title: 'Hiking')
    media_object.update_datastream(:descMetadata, creator: 'Adam')
    media_object.update_datastream(:descMetadata, date_issued: 'January 2007')
    media_object.save

    master_file = MasterFile.new(pid:'avalon:hiking-movie')
    master_file.status_code =  ['STOPPED']
    master_file.file_location = 'something/granite-mountain-hike.mov'
    master_file.percent_complete = ['100']

    media_object.parts << master_file
    media_object.save(validate: false)

    ingest_batch = IngestBatch.create( media_object_ids: [media_object.id])

    email = IngestBatchMailer.status_email( ingest_batch.id )
    email_message = Capybara.string(email.body.to_s)

    # Ideally a within block would be nice here
    fragment = email_message.find("table > tbody > tr:nth-child(1)")
    fragment.find('.master-file').should have_content(File.basename(master_file.file_location))
    fragment.find('.percent-complete').should have_content(master_file.percent_complete.first)
    fragment.find('.status-code').should have_content(master_file.status_code.first.downcase.titleize)
  end
end
