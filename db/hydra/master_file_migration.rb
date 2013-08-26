class MasterFileMigration < Hydra::Migrate::Migration
  migrate nil => 'R2' do |obj,ver,dispatcher|
    dispatcher.migrate!(obj.derivatives)
    obj.duration = obj.derivatives.empty? ? 0 : obj.derivatives.first.duration
    obj.descMetadata.poster_offset = obj.descMetadata.thumbnail_offset = [obj.duration.to_i,2000].min.to_s
  end
end
