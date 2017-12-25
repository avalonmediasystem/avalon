if File.exist?('/sys/hypervisor/uuid') && (File.read('/sys/hypervisor/uuid',3) == 'ec2')
  require 'aws/rails/mailer'
  ActionMailer::Base.delivery_method = :aws_sdk
end
