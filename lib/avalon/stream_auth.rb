# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

module Avalon
	class StreamAuth
		def initialize(app, options={})
			@app = app
			@opts = { :prefix => '/streams/' }.merge(options)
		end

		def call(env)
			if env["PATH_INFO"] =~ %r{#{@opts[:prefix]}.+\.m3u8$} and env["REQUEST_METHOD"] != 'HEAD'
				stream_path = env["PATH_INFO"][@opts[:prefix].length..-1]
				auth_env = env.dup
				auth_path = "/authorize"
				auth_env.merge!({
					"HTTP_ACCEPT"  => "text/plain",
					'PATH_INFO'    => auth_path,
					'REQUEST_PATH' => auth_path,
					'REQUEST_URI'  => "#{auth_path}?#{auth_env['QUERY_STRING']}"
				})
				(status, headers, resp) = @app.call(auth_env)
				content = resp.body.strip
				resp.close
				if status == 202
					content.split(/\n/).each do |auth_stream|
						if stream_path.index(auth_stream)
							file = File.expand_path("./public/#{env['PATH_INFO']}")
							if File.exists?(file)
								return [200, {
										'Content-Length' => File.size(file),
										'Content-Type'   => Rack::Mime.mime_type(File.extname(file))
									}, File.new(file)]
							else
								return [404, {}, []]
							end
						end
					end
					return [403, {}, []]
				else
					[status, headers, resp]
				end
			else
				@app.call(env)
			end
		end
	end
end
