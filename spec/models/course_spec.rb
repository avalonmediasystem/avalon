# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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

describe Course do
  let! (:course)        { FactoryGirl.create(:course)       }
  let! (:media_objects) { [FactoryGirl.create(:media_object),FactoryGirl.create(:media_object)] }
  
  context "Pre-existing MediaObjects" do
    before :each do
      media_objects[0].read_groups = [course.label]
      media_objects[1].read_groups = [course.title]
      media_objects.each(&:save)
    end
    
    it "#fix_object_rights!" do
      media_objects.each do |mo|
        mo.reload
        expect(mo.read_groups).not_to include(course.context_id)
      end
      
      course.fix_object_rights!
      
      media_objects.each do |mo|
        mo.reload
        expect(mo.read_groups).not_to include(course.label)
        expect(mo.read_groups).not_to include(course.title)
        expect(mo.read_groups).to     include(course.context_id)
      end
    end
  end
end
