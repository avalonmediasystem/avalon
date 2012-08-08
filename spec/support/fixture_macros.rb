module FixtureMacros
  def load_fixture(pid)
    remove_fixture(pid)
    ActiveFedora::FixtureLoader.new(File.dirname(__FILE__) + '/../fixtures').reload(pid)
    puts "Refreshed #{pid}"
  end

	def remove_fixture(pid)
    if Video.exists?(pid)
        video = Video.find(pid)
        video.parts.each do |part|
        ActiveFedora::FixtureLoader.delete(part.pid)
        puts "Deleted #{part.pid}"
        end
    end
  end
  
  def clean_groups(groups)
    groups.each do |group|
      if !RoleControls.users(group).nil?
        RoleControls.remove_role(group)
      end
    end
  end
end

