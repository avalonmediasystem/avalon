# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

module FixtureMacros
  def load_fixture(pid, status='published')
    remove_fixture(pid)
    ActiveFedora::FixtureLoader.new(File.dirname(__FILE__) + '/../fixtures').reload(pid)
#    @ingest_status = FactoryGirl.build(:new_status, pid: pid, current_step: status, published: (status == 'published' ? true : false))
#    @ingest_status = FactoryGirl.build(:new_status, pid: pid)
#    @ingest_status.save
#    logger.debug "Refreshed #{pid} with status #{@ingest_status.inspect}"
  end

	def remove_fixture(pid)
    if MediaObject.exists?(pid)
        mediaobject = MediaObject.find(pid)
        mediaobject.parts.each do |part|
        ActiveFedora::FixtureLoader.delete(part.pid)
        end
    end
  end
  
  def clean_groups(group_names)
    group_names.each do |group_name|
      g = Admin::Group.find(group_name)
      g.delete unless g.blank?
    end
  end
end
