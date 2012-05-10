Given /^that the following PIDs? exists?: (.*)$/ do |pid_list|
  pids = pid_list.split(", ")
  pids.each do |pid|
   prepare_system(pid)
  end
end

# Loads a mock object into the 
def prepare_system(id)
  # Delete the existing PID if it already exists
  ActiveFedora::Base.find(id).delete if Video.exists?(id)

  # Create a new video object - need to make sure that all the datastreams (such as
  # descMetadata) are properly attached
  vid = Video.new(pid: id)
  # Poke the descriptive metadata to make it spawn
  vid.descMetadata
  vid.save
  puts "#{id} has been reset in the system"
end
