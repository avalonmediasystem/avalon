#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

# Detects the Avalon version by using a shared lib
# Version should be sematic format like this:
# major.minor.patch.build
# Must have at least major.minor
# Supported examples:
# 7.3
# 7.3.0
# 7.3.0.15

require("#{__dir__}/../lib/avalon/build_utils.rb")
utils = Avalon::BuildUtils.new
version = utils.detect_version
puts version
