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

RSpec.describe TimelinesHelper, type: :helper do

  describe '#timeline_human_friendly_visibility' do

    subject { timeline_human_friendly_visibility(visibility) }
    context 'should return icon and string for public visibility' do
      let(:visibility){ Timeline::PUBLIC }
      it{ is_expected.to include('human_friendly_visibility_public') }
      it{ is_expected.to include(t("timeline.publicText")) }
      it{ is_expected.to include(t("timeline.publicAltText")) }
    end
    context 'should return icon and string for private visibility' do
      let(:visibility){ Timeline::PRIVATE }
      it{ is_expected.to include('human_friendly_visibility_private') }
      it{ is_expected.to include(t("timeline.privateText")) }
      it{ is_expected.to include(t("timeline.privateAltText")) }
    end
    context 'should return icon and string for private-with-token visibility' do
      let(:visibility){ Timeline::PRIVATE_WITH_TOKEN }
      it{ is_expected.to include('human_friendly_visibility_private-with-token') }
      it{ is_expected.to include(t("timeline.private-with-tokenText")) }
      it{ is_expected.to include(t("timeline.private-with-tokenAltText")) }
    end
  end
end
