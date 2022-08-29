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

module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?
    flash[:error] = simple_format I18n.t("errors.messages.not_saved",
                                          count: resource.errors.count,
                                          resource: resource.class.model_name.human.downcase,
                                          message: error_message(resource)
                                        )
  end

  private

    def error_message(resource)
      message = []
      resource.errors.messages.each do |key, messages|
        m = if key == :email || key == :username
              "#{key.capitalize} \"#{resource.errors&.details[key]&.first&.[](:value)}\" #{messages&.join(' and ')}"
            else
              "#{key.to_s.tr('_', ' ').capitalize} #{messages.join(' and ')}"
            end
        message.append(m)
      end
      message.join("\n- ").prepend("- ")
    end
end
