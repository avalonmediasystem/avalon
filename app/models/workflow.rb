# --- BEGIN LICENSE_HEADER BLOCK ---
# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class Workflow
  @_states = []
  @_states_order = []
  
  def initialize(*steps)
    @_states = {}
    @_states_order = []
  
    steps.each do |step|
      @_states[step.step.to_s] = step
      @_states_order.push(step.step)
    end
    @_states.freeze
    @_states_order.freeze
  end
  
  def get_step(name)
    @_states[name]
  end

  def first?(step)
    step == @_states_order.first
  end
  
  def first
    @_states[@_states_order.first]
  end
  
  def last
    @_states[@_states_order.last]
  end
  
  def last?(step)
    step == @_states_order.last
  end

  def has_next?(step)
    not self.next(step).nil?
  end
  
  def next(step)
    offset = get_key_index(step)
    next_step = nil
    
    unless last?(step) or offset.nil?
      offset = offset + 1
      next_step = @_states[@_states_order[offset]]
    end
    
    # Return the next step
    next_step
  end
  
  def previous(step)
    offset = get_key_index(step)
    previous_step = nil
    
    unless first?(step) or offset.nil?
      offset = offset - 1
      previous_step = @_states[@_states_order[offset]]
    end
    
    # Return the next step
    previous_step
  end
  
  def index(step)
    index = get_key_index(step)
    unless index.nil?
      index + 1
    else
      nil
    end
  end
  
  def exists?(step)
    @_states.key?(step)
  end
  
  # Override so it returns a array of just the steps
  def to_a
    @_states.values
  end
  
  def template(step)
    target_step = @_states[step]
    target_step.template
  end
        
  protected
  def get_key_index(step)
    @_states_order.index(step)
  end
end
