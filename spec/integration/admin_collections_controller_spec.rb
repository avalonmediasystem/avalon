# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

require 'rails_helper.rb'

describe 'Admin::CollectionsController' do
  describe 'resize_uploaded_poster' do
    let(:uploaded_file) { fixture_file_upload('/collection_poster.jpg', 'image/jpeg') }
    let(:controller) { Admin::CollectionsController.new }

    it 'successfully runs mini_magick' do
      expect(controller.send(:resize_uploaded_poster, uploaded_file.path)).not_to be_empty
    end

    context 'when passed an invalid file' do
      let(:uploaded_file) { fixture_file_upload('/captions.vtt', 'text/vtt') }

      it 'returns nil' do
        expect(controller.send(:resize_uploaded_poster, uploaded_file.path)).to be_nil
      end
    end
  end
end