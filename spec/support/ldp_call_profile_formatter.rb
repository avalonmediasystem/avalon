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

# frozen_string_literal: true
# Taken from Hyrax and modified
RSpec::Support.require_rspec_core "formatters/base_text_formatter"
class LdpCallProfileFormatter < RSpec::Core::Formatters::ProfileFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_finished, :dump_profile
  def initialize(output)
    @output = output
    @profile = []
    reset!
    ActiveSupport::Notifications.subscribe("http.ldp", method(:record_request))
  end

  def record_request(*_unused, data)
    @request_count += 1
    @request_count_by_name[data[:name]] += 1
  end

  def example_finished(notification)
    @profile += [{ example: notification.example, count: @request_count, count_by_name: @request_count_by_name }]
  end

  def example_started(_notification)
    reset!
  end

  def reset!
    @request_count = 0
    @request_count_by_name = { 'HEAD' => 0,
                               'GET' => 0,
                               'POST' => 0,
                               'DELETE' => 0,
                               'PUT' => 0,
                               'PATCH' => 0 }
  end

  def dump_profile(profile)
    @output.puts ""
    dump_most_ldp_exampes(profile)
    dump_slowest_examples(profile)
  end

  private

  def dump_most_ldp_exampes(_prof)
    @output.puts "Examples with the most LDP requests"
    top = @profile.sort_by { |hash| hash[:count] }.last(10).reverse
    top.each do |hash|
      result = hash[:count_by_name].select { |_, v| v.positive? }
      next if result.empty?
      @output.puts "  #{hash[:example].full_description}"
      @output.puts "    #{hash[:example].location}"
      @output.puts "    Total LDP: #{hash[:count]} #{result}"
    end
  end

  def dump_slowest_examples(profile)
    RSpec::Core::Formatters::ProfileFormatter.new(@output).dump_profile(profile)
  end
end
