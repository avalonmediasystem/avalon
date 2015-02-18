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

module Avalon
  class ControlledVocabulary

    def self.vocabulary
      vocabulary = {}
      path = Rails.root.join(Avalon::Configuration.lookup('controlled_vocabulary.path'))
      if File.file?(path)
        yaml = YAML::load(File.read(path))
        vocabulary = yaml.symbolize_keys if yaml.present?
      end
      vocabulary
    end

    def self.find_by_name( name )
      vocabulary[name.to_sym]
    end
  end
end
