# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe 'ActiveFedora::Base' do
  let(:new_obj) { ActiveFedora::Base.new }
  let(:obj) { ActiveFedora::Base.create }

  # This tests changes overrides that are in config/initializers/active_fedora_general.rb
  context 'when read-only mode' do
    before { allow(Settings).to receive(:repository_read_only_mode).and_return(true) }

    it 'raises ReadOnlyRecord for any write operation' do
      expect { ActiveFedora::Base.create }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { new_obj.save }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { new_obj.save! }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.save }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.save! }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.update }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.update! }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.delete }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.destroy }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.destroy! }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { obj.eradicate }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { ActiveFedora::Base.eradicate(obj.to_uri) }.to raise_error ActiveFedora::ReadOnlyRecord
      expect { ActiveFedora::Base.delete_tombstone(obj.to_uri) }.to raise_error ActiveFedora::ReadOnlyRecord
    end
  end
end
