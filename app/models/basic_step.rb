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

# basic_step.rb
#
# This template lays out the API for implementing your own custom steps. As a
# class it should never be used since its own implementations are trivial at
# best (unless you need a NoOp operation)
#
# Workflow state is designed to be chained so that multiple operations can be
# performed in sequence. Make sure that your own steps return the modified
# application context for use by methods down the line
class BasicStep
  attr_accessor :step, :title, :summary, :template

  def initialize(step = nil, title = nil, summary = nil, template = nil)
    self.step = step
    self.title = title
    self.summary = summary
    self.template = template
  end

  # before_step will execute to set the context for an operation.
  # If you need to load options for forms, verify MD5 checksums, or
  # other similar functions this is the place to perform those
  # calls 
  #
  # This method is analogous to the processing that would take place
  # within the edit step of a controller to set up the view and
  # environment for users
  def before_step context
    context
  end

  # after_step does the same except that it will fire once a step's
  # perform method has finished. Example implementations here might
  # include moving files, cleaning up and validating metadata, or
  # rewinding the current step if it should not advance
  def after_step context
    context
  end

  # execute should take care of the actual events that need to happen
  # when an operation is triggered. The context object which is passed
  # should provide all the necessary information for the step. Any
  # changes should be pushed out through the context object.
  #
  # If a step has certain dependencies beyond the basic Hydra options
  # they should be expressed locally (ie at the top of that step).
  def execute context
    context
  end
end
