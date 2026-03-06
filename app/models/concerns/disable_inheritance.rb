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

module DisableInheritance
  extend ActiveSupport::Concern

  def disable_inheritance= value
    groups = self.discover_groups
    if value
      groups += ["no_parents"]
    else
      groups -= ["no_parents"]
    end
    self.discover_groups = groups.uniq
  end

  def disable_inheritance?
    self.discover_groups.include? "no_parents"
  end

  def to_solr(solr_doc = {})
    super.tap do |doc|
      doc['disable_inheritance_bsi'] = disable_inheritance?
    end
  end
end
