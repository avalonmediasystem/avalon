module Hydrant
	class StreamAuth
		def initialize(app, options={})
			@app = app
			@opts = { :prefix => '/streams/' }.merge(options)
		end

		def call(env)
			if env["PATH_INFO"] =~ %r{#{@opts[:prefix]}.+\.m3u8$} and env["REQUEST_METHOD"] != 'HEAD'
				mediapackage_id = env["PATH_INFO"][@opts[:prefix].length..-1].split(%r{/}).first
				auth_env = env.dup
				auth_path = "/authorize"
				auth_env.merge!({
					"HTTP_ACCEPT"  => "text/plain",
					'PATH_INFO'    => auth_path,
					'REQUEST_PATH' => auth_path,
					'REQUEST_URI'  => "#{auth_path}?#{auth_env['QUERY_STRING']}"
				})
				(status, headers, resp) = @app.call(auth_env)
				content = resp.body.body.strip
				resp.close
				if status == 202
					auth_mediapackage = content
					if auth_mediapackage == mediapackage_id
						file = File.expand_path("./public/#{env['PATH_INFO']}")
						[200, {
								'Content-Length' => File.size(file),
								'Content-Type'   => Rack::Mime.mime_type(File.extname(file))
							}, File.new(file)]
					else
						[403, {}, []]
					end
				else
					[status, headers, resp]
				end
			else
				@app.call(env)
			end
		end
	end
end