class EncodingProfileDocument < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path=>"encodingProfile", 
           :xmlns => 'avalon/encoding', 
           :namespace_prefix=>nil)

    # The quality is a quick way to determine which stream to provide
    # on the fly
    #
    # Expected values are 'low', 'medium', and 'high'
    t.quality(path: 'quality')
    # MIME type is provided to the player so it can serve the right context
    # to the user
    t.mime_type(path: 'mime_type')
    
    t.audio(path: 'audio') {
      t.audio_bitrate(path: 'bitrate')
      t.audio_codec(path: 'codec')
    }

    t.video(path: 'video') {
      t.video_bitrate(path: 'bitrate')
      t.video_codec(path: 'codec')

      t.resolution {
        t.video_width(path: 'width')
        t.video_height(path: 'height')
      }
      t.frame_rate(path: 'framerate')
    }
   end
   
   def blank_template
     t.encodingProfile {
       t.quality
       t.mime_type

       t.audio {
         t.audio_bitrate
         t.audio_codec
       }
     }
   end
end
