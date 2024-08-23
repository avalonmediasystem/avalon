# Set up for active_encode, need to happen before active_encode initializer
ENV["MEDIAINFO_PATH"] ||= Settings.mediainfo.path if Settings&.mediainfo&.path