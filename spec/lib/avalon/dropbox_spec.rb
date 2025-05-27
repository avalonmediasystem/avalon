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
require 'avalon/dropbox'


describe Avalon::Dropbox do

  describe "#delete" do
    before :each do
      FactoryBot.create(:user, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com')
      Avalon::RoleControls.add_user_role('frances.dickens@reichel.com','manager')
    end

    let(:collection) { FactoryBot.create(:collection, name: 'Ut minus ut accusantium odio autem odit.', managers: ['frances.dickens@reichel.com']) }
    subject { Avalon::Dropbox.new(Settings.dropbox.path,collection) }
    it 'returns true if the file is found' do
      allow(File).to receive(:delete).and_return true
      subject.delete('some_file.mov')
    end

    it 'returns false if the file is not found' do
      expect(subject.delete('some_file.mov')).to be false
    end

  end

end
