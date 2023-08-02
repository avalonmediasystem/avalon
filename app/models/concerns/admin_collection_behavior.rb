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

# This module contains methods which transform stored values for use either on Admin::Collection or the SpeedyAF presenter
module AdminCollectionBehavior
  def managers
    edit_users & collection_managers.to_a
  end

  def editors
    edit_users - managers
  end

  def editors_and_managers
    edit_users
  end

  def depositors
    read_users
  end
end