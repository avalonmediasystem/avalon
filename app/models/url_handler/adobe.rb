module UrlHandler
	class Adobe

		def self.patterns
			{
				'rtmp' => {
					'video' => "<%=prefix%>:<%=media_id%>/<%=stream_id%>/<%=filename%>",
					'audio' => "<%=prefix%>:<%=media_id%>/<%=stream_id%>/<%=filename%>",
				},
				'http' => {
					'video' => "<%=media_id%>/<%=stream_id%>/<%=filename%>.<%=extension%>.m3u8",
					'audio' => "audio-only/<%=media_id%>/<%=stream_id%>/<%=filename%>.<%=extension%>.m3u8",
				}
			}
		end

	end
end