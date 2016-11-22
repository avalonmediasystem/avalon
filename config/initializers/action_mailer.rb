ActionMailer::DeliveryJob.rescue_from(StandardError) do |exception|
  Rails.logger.error "Error delivering mail: #{exception}"
end
