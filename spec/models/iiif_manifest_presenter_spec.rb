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
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'rails_helper'

describe IiifManifestPresenter do
  let(:media_object) { FactoryBot.build(:media_object) }
  let(:master_file) { FactoryBot.build(:master_file, media_object: media_object) }
  let(:presenter) { described_class.new(media_object: media_object, master_files: [master_file]) }

  context 'homepage' do
    subject { presenter.homepage.first }

    it 'provices a homepage' do
      expect(subject[:id]).to eq Rails.application.routes.url_helpers.media_object_url(media_object)
      expect(subject[:type]).to eq "Text"
      expect(subject[:format]).to eq "text/html"
      expect(subject[:label]).to include("none" => ["View in Repository"])
    end
  end
end
