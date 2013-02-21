# This file is used by Rack-based servers to start the application.
require ::File.expand_path('../config/environment',  __FILE__)
require 'hydrant/stream_auth'

use Hydrant::StreamAuth, :prefix => '/streams/'
run Hydrant::Application
