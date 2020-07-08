require 'mediainfo'

Mediainfo.path = Settings.mediainfo.path if Settings&.mediainfo&.path

# Set up for active_encode, need to happen before active_encode initializer
ENV["MEDIAINFO_PATH"] ||= Mediainfo.path 