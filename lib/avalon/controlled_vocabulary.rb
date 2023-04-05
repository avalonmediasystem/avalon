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

module Avalon
  class ControlledVocabulary

    @@path = Rails.root.join(Settings.controlled_vocabulary.path)

    def self.vocabulary
      vocabulary = {}
      if File.file?(@@path)
        yaml = YAML::load(File.read(@@path))
        vocabulary = yaml.symbolize_keys if yaml.present?
      end
      vocabulary
    end

    # Threadsafe writing to controlled vocabulary yaml
    # @param [Hash] vocabulary The new vocabulary to save
    # @returns [Hash, false] The newly saved vocabulary, or false if save unable to obtain lock
    def self.vocabulary= vocabulary
      f = File.open(@@path, File::RDWR|File::TRUNC|File::CREAT, 0644)
      if f.flock(File::LOCK_NB|File::LOCK_EX)
        YAML.dump(vocabulary, f)
        f.flock(File::LOCK_UN)
      else
        false
      end
    end

    def self.find_by_name( name, sort: false )
      vocab = vocabulary[name.to_sym]
      sort ? vocab.sort : vocab
    end

  end
end
