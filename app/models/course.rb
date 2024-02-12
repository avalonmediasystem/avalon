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

class Course < ActiveRecord::Base
#  attr_accessible :context_id, :label, :title

  def self.autocomplete(query, _id = nil)
    self.where("label LIKE :q OR title LIKE :q", q: "%#{query}%").collect { |course|
      { id: course.context_id, display: course.title }
    }
  end

  def self.unlink_all(context_id)
    MediaObject.find_each(read_access_group_ssim: context_id) do |mo|
      mo.read_groups = mo.read_groups - [context_id]
      mo.update_index
    end
  end

end
