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


module ConditionalPartialsHelper
  def render_conditional_partials(partials_list_name, options={}, &block)
    content = []
    partials = controller.class.conditional_partials[partials_list_name]
    partials.select { |_, config| evaluate_if_unless_configuration config, options }.each do |key, config|
      config[:key] ||= key
      rendered = render(partial: config[:partial] || key.to_s, locals:{ partial_config: config }.merge(options))
      if block_given?
        yield config, rendered
      else
        content << rendered
      end
    end
    safe_join(content, "\n") unless block_given?
  end

  ##
  # Determine whether any item in partial_list will be rendered by evaluating :if and :unless conditions
  #
  # @param [Symbol] partials_list_name
  # @return [Boolean]
  def will_partial_list_render? partials_list_name, *args
    partials = controller.class.conditional_partials[partials_list_name]
    partials.select { |_, config| evaluate_if_unless_configuration config, *args }.present?
  end

  ##
  # Evaluate conditionals for a configuration with if/unless attributes
  #
  # @param displayable_config [#if,#unless] an object that responds to if/unless
  # @return [Boolean]
  def evaluate_if_unless_configuration displayable_config, *args
    return displayable_config if displayable_config === true or displayable_config === false

    if_value = !displayable_config.has_key?(:if) ||
                    displayable_config[:if].nil? ||
                    evaluate_configuration_conditional(displayable_config[:if], displayable_config, *args)
    
    unless_value = !displayable_config.has_key?(:unless) ||
                      displayable_config[:unless].nil? ||
                      !evaluate_configuration_conditional(displayable_config[:unless], displayable_config, *args)

    if_value && unless_value
  end
  
  def evaluate_configuration_conditional proc_helper_or_boolean, *args_for_procs_and_methods
    case proc_helper_or_boolean
    when Symbol
      arity = method(proc_helper_or_boolean).arity

      if arity == 0
        send(proc_helper_or_boolean)
      else 
        send(proc_helper_or_boolean, *args_for_procs_and_methods)
      end
    when Proc
      proc_helper_or_boolean.call self, *args_for_procs_and_methods
    else
      proc_helper_or_boolean
    end
  end
end
