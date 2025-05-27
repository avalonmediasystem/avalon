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
#require 'capybara/rspec'

describe 'Batch Ingest Email' do

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'has an error if media object has not been set' do
    ingest_batch = IngestBatch.create
    @email = IngestBatchMailer.status_email( ingest_batch.id  )
    expect(@email).to have_body_text('There was an error.  It appears no files have been submitted')
  end

  it 'has an error if there are no media objects present' do
    @ingest_batch = IngestBatch.create( media_object_ids: [])
    @email = IngestBatchMailer.status_email( @ingest_batch.id )
    expect(@email).to have_body_text('There was an error.  It appears no files have been submitted')
  end

  it 'shows the title of one media object' do
    media_object = FactoryBot.create(:media_object)
    ingest_batch = IngestBatch.create(media_object_ids: [media_object.id])
    @email = IngestBatchMailer.status_email(ingest_batch.id)
    expect(@email).to have_body_text(media_object.title)
  end

  it 'has the status of the master file in a first row' do
    master_file = FactoryBot.create(:master_file, :with_media_object)
    media_object = master_file.media_object.reload

    ingest_batch = IngestBatch.create( media_object_ids: [media_object.id])

    email = IngestBatchMailer.status_email( ingest_batch.id )
    email_message = Capybara.string(email.body.to_s)

    # Ideally a within block would be nice here
    fragment = email_message.find("table > tbody > tr:nth-child(1)")
    expect(fragment.find('.master-file')).to have_content(File.basename(master_file.file_location))
    expect(fragment.find('.percent-complete')).to have_content(master_file.percent_complete)
    expect(fragment.find('.status-code')).to have_content(master_file.status_code.downcase.titleize)
  end
end
