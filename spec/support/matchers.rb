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

RSpec::Matchers.define :hash_match do |expected|
  match do |actual|
    diff = Hashdiff.diff(actual,expected) do |p,a,e|
      if a.is_a?(RealFile) && e.is_a?(RealFile)
        FileUtils.cmp(a,e)
      elsif a.is_a?(File) && e.is_a?(File)
        FileUtils.cmp(a,e)
      elsif p == ""
         nil
      else
        a.eql? e
      end
    end
    diff == []
  end
end
