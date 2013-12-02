require 'avalon/matterhorn_rtmp_url'

class AddAbsoluteLocationToDerivative < ActiveRecord::Migration
  def change
    stream_base = Rubyhorn.client.me['org']['properties']['avalon.stream_base']
    raise 'Error: stream base must be set in the Matterhorn configuration' unless stream_base.present?
    Derivative.all.each do |derivative|
      if !derivative.absolute_location.present? and derivative.location_url.present?
        derivative.absolute_location = File.join(stream_base, Avalon::MatterhornRtmpUrl.parse(derivative.location_url).to_path)
        derivative.save( validate: false )
      end
    end
  end
end
