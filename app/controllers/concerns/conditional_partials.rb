# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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


module ConditionalPartials
  extend ActiveSupport::Concern

  included do
    class_attribute :conditional_partials, instance_accessor: false, instance_predicate: false
    self.conditional_partials = {}
  end

  module ClassMethods
    def add_conditional_partial partial_list_name, name, opts={}
      conditional_partials[partial_list_name] ||= {}
      config = opts
      config[:name] = name

      if block_given?
        yield config
      end

      conditional_partials[partial_list_name][name] = config
    end
  end
end
