# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

# Validate that a settings hash is a hash and contains required values
class SettingsHashValidator < ActiveModel::EachValidator
  REQUIRED_KEYS = {
    bib_retriever: [:url, :protocol, :retriever_class],
    intercom: [:url, :api_token]
  }.freeze

  def validate_each(record, attribute, hash)
    if !hash.is_a?(Hash)
      record.errors.add(attribute, "config must be a JSON hash")
    elsif hash.is_a?(Hash) && !hash.empty? && hash.values.all?(Hash)
      hash.each { |k, v| validate_hash_contents(v, k, attribute, record) }
    elsif hash.is_a?(Hash) && !hash.empty?
      record.errors.add(attribute, 'must specify a service for each config e.x. { "default": { "url": "example.com" }, "custom": { "url": "custom.com" } }')
    end
  end

  private

  def validate_hash_contents(hash, parent_key, service, record)
    REQUIRED_KEYS[service].each { |param| record.errors.add(service, "config '#{parent_key}' missing required param: '#{param}'") unless hash.key?(param) }
  end
end
