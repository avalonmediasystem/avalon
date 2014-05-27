class ExternalGroup
  def self.autocomplete(query)
    Course.autocomplete(query) + Admin::Group.autocomplete(query)
  end
end
