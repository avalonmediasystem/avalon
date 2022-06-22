# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

namespace :deploy do  
  namespace :symlink do
    desc "Resolve globs in linked_files"
    task :glob do
      new_linked_files = []
      on release_roles :all do
        within shared_path do
          Array(fetch(:linked_files, [])).each do |linked_file|
            if linked_file =~ /[\?\*]/
              new_linked_files += capture(:ls, linked_file, raise_on_non_zero_exit: false).split
            else
              new_linked_files << linked_file
            end
          end
        end
      end
      set :linked_files, new_linked_files
    end
  end
end
before "deploy:check", "deploy:symlink:glob"
