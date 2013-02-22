# This file is used by Rack-based servers to start the application.
require ::File.expand_path('../config/environment',  __FILE__)
require 'avalon/stream_auth'

use Avalon::StreamAuth, :prefix => '/streams/'
run Avalon::Application
