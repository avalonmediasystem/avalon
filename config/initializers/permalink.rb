if Settings.permalink.present? && Settings.permalink.host.present? && Settings.permalink.template.present?
  PERMALINK_SEMAPHORE = Mutex.new
  PERMALINK_TEMPLATE = Settings.permalink.template
  Permalink.on_generate do |obj, url|
    noid = nil
    PERMALINK_SEMAPHORE.synchronize do
	    File.open(File.join(Rails.root, Settings.permalink.minter_state_file), File::RDWR|File::CREAT, 0644) do |f|
        f.flock(File::LOCK_EX)
        yaml = YAML::load(f.read)
        yaml = {template: PERMALINK_TEMPLATE} unless yaml
        minter = ::Noid::Minter.new(yaml)
        begin
          noid = minter.mint
        end until ActiveFedora::Base.where("identifier_ssim:#{noid}").first.nil?
        f.rewind
        yaml = YAML::dump(minter.dump)
        f.write yaml
        f.flush
        f.truncate(f.pos)
      end
    end
    raise 'NOID not able to be generated' unless noid
    obj.identifier += [noid]
    URI.join(Settings.permalink.host, noid).to_s
  end
end
