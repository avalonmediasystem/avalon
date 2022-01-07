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

module FedoraMigrate
  module AdminCollection
    class DefaultRightsDatastreamMover < PermissionsMover
      def migrate
        [:read_groups, :read_users].each do |permission|
          next unless target.respond_to?("default_" + permission.to_s + "=")
          report << "default_#{permission} = #{send(permission)}"
          target.send("default_" + permission.to_s + "=", send(permission))
        end
        target.default_hidden = discover_groups.include?("nobody") if target.respond_to?("default_hidden=")
        report << "default_hidden = #{target.default_hidden}"
        # save
        # super
        report
      end
    end
  end
end
