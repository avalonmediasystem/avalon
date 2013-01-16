module FixtureMacros
  def load_fixture(pid, status='published')
    remove_fixture(pid)
    ActiveFedora::FixtureLoader.new(File.dirname(__FILE__) + '/../fixtures').reload(pid)
#    @ingest_status = FactoryGirl.build(:new_status, pid: pid, current_step: status, published: (status == 'published' ? true : false))
#    @ingest_status = FactoryGirl.build(:new_status, pid: pid)
#    @ingest_status.save
#    logger.debug "Refreshed #{pid} with status #{@ingest_status.inspect}"
    logger.debug "Refreshed #{pid}"
  end

	def remove_fixture(pid)
    if MediaObject.exists?(pid)
        mediaobject = MediaObject.find(pid)
        mediaobject.parts.each do |part|
        ActiveFedora::FixtureLoader.delete(part.pid)
        logger.debug "Deleted #{part.pid}"
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

