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

namespace :avalon do
  desc "Link hls dir to public/streams"
  task :link_hls_dir do
    source = fetch(:hls_dir, nil)
    unless source.nil?
      target = release_path.join('public/streams')
      on roles(:web) do
        execute :ln, "-s", source, target
      end
    end
  end
end
after "deploy:updated", "avalon:link_hls_dir"
