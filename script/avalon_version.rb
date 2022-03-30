#!/usr/bin/env ruby
# frozen_string_literal: true

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
