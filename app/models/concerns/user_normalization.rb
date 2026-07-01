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

module UserNormalization
  # Method to normalize just read user fields.
  def normalize_read_users
    field = self.class == MediaObject ? :read_users : :default_read_users
    user_array = send(field)
    setter = "#{field}=".to_sym
    send(setter, user_array.map(&:downcase))
  end

  # Method to normalize all fields containing usernames/emails
  # TODO: Find consistent way to skip unchanged fields
  def normalize_user_values
    user_methods = methods.grep(/users$/).reject { |m| m.to_s.include?('set') }
    user_methods += [:unit_administrators, :collection_managers]
    user_methods.each do |field|
      user_array = send(field)
      setter = "#{field}=".to_sym
      send(setter, user_array.map(&:downcase))
    rescue
      # Skip any methods that do not exist in the including class e.g. :unit_administrators
      # when loaded into Admin::Collections
      next
    end
  end
end
