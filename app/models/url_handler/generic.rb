module UrlHandler
	class Generic

		def self.patterns
			{
				'rtmp' => {
					'video' => "<%=prefix%>:<%=media_id%>/<%=stream_id%>/<%=filename%>",
					'audio' => "<%=prefix%>:<%=media_id%>/<%=stream_id%>/<%=filename%>",
				},
				'http' => {
					'video' => "<%=media_id%>/<%=stream_id%>/<%=filename%>.<%=extension%>.m3u8",
					'audio' => "<%=media_id%>/<%=stream_id%>/<%=filename%>.<%=extension%>.m3u8",
				}
			}
		end

	end
end
