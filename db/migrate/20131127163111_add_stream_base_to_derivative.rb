class AddStreamBaseToDerivative < ActiveRecord::Migration
  def change
    stream_base = Rubyhorn.client.me['org']['properties']['avalon.stream_base']
    raise 'Error: stream base must be set in the Matterhorn configuration' unless stream_base.present?
    Derivative.all.each do |derivative|
      if ! derivative.absolute_location.present?
        derivative.absolute_location = stream_base
        derivative.save( validate: false )
      end
    end
  end
end
