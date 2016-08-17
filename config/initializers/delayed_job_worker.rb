Delayed::Worker.destroy_failed_jobs = false 
Delayed::Worker.logger = Logger.new(Rails.root.join('log', 'delayed_job.log'))
