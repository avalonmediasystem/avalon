class MigrationStatus < ActiveRecord::Base
  DETAIL_STATUSES = ['completed','failed','waiting']

  def self.summary
    counts = MigrationStatus.where(datastream: nil).group(:source_class, :status).count
    MigrationStatus.pluck(:source_class).uniq.inject({}) do |h,klass|
      h[klass] = {}
      DETAIL_STATUSES.each do |s|
        h[klass][s] = counts[[klass, s]].to_i
      end
      h[klass]['in progress'] = counts.select { |k,v| k[0] == klass and not DETAIL_STATUSES.include?(k[1]) }.values.sum
      h[klass]['total'] = counts.select { |k,v| k[0] == klass }.values.sum
      h
    end
  end
end
