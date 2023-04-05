# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe Admin::Group do

  describe "name" do
    it { is_expected.to validate_presence_of( :name )}
    it { is_expected.not_to allow_value( 'group.01' ).for( :name )}
    it { is_expected.not_to allow_value( 'group;01' ).for( :name )}
    it { is_expected.not_to allow_value( 'group%01' ).for( :name )}
    it { is_expected.not_to allow_value( 'group/01' ).for( :name )}
  end

  describe "non system groups" do
    it "should not have system groups" do
      groups = Admin::Group.non_system_groups
      system_groups = Settings.groups.system_groups
      groups.each { |g| expect(system_groups).not_to include g.name }
    end
  end

end
