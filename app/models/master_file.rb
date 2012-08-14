class MasterFile < FileAsset
  include ActiveFedora::Relationships
  has_bidirectional_relationship "derivatives", :has_derivation, :is_derivation_of

  def derivatives_append(der)
    der.add_relationship(:is_derivation_of, self)
    der.save
  end
end
