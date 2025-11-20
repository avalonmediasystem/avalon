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

# This module contains methods which transform stored values for use either on Admin::Collection or the SpeedyAF presenter
module AdminCollectionBehavior
  def managers
    edit_users & collection_managers.to_a
  end

  def inherited_managers
    unit.unit_admins_and_managers
  end

  def editors
    edit_users - managers
  end

  def inherited_editors
    unit.editors
  end

  def editors_and_managers
    edit_users
  end

  def depositors
    read_users
  end

  def inherited_depositors
    unit.depositors
  end

  def inherited_read_users
    unit.default_read_users
  end

  def inherited_read_groups
    unit.default_read_groups
  end

  def inherited_local_read_groups
    unit.default_local_read_groups
  end

  def inherited_ip_read_groups
    unit.default_ip_read_groups
  end

  def inherited_virtual_read_groups
    unit.default_virtual_read_groups
  end
end
