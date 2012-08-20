# This requires Ruby 1.9.x to function properly. The behaviour of the Hash class in
# prior versions does not guarantee that the ordering will work properly. This should
# be documented after the quick and dirty solution is in place.
    class IngestWorkflow
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
      
      def first?(step_name)
        step_name == @_states_order.first
      end
      
      def first
        @_states[@_states_order.first]
      end
      
      def last
        @_states[@_states_order.last]
      end
      
      def last?(step_name)
        step_name == @_states_order.last
      end
      
      def next(step_name)
        offset = get_key_index(step_name)
        next_step = nil
        
        puts "<< #{offset} (#{next_step}) >>"
        
        unless last?(step_name) or offset.nil?
          offset = offset + 1
          next_step = @_states[@_states_order[offset]]
        end
        
        # Return the next step
        next_step
      end
      
      def previous(step_name)
        offset = get_key_index(step_name)
        previous_step = nil
        
        unless first?(step_name) or offset.nil?
          offset = offset - 1
          previous_step = @_states[@_states_order[offset]]
        end
        
        # Return the next step
        previous_step
      end
      
      def index(step_name)
        index = get_key_index(step_name)
        unless index.nil?
          index + 1
        else
          nil
        end
      end
      
      # Override so it returns a array of just the steps
      def to_a
        @_states.values
      end
      
      def template(step_name)
        target_step = @_states[step_name]
        target_step.template
      end
      
      protected
      def get_key_index(step_name)
        @_states_order.index(step_name)
      end
    end
