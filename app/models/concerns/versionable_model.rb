module VersionableModel

  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :model_version

    def has_model_version(value)
      @model_version = value
      self.before_save :update_current_version!
    end
  end

  def update_current_version!
    if self.class.model_version and not @auto_versioning_disabled
      self.current_version = self.class.model_version
    end
  end

  def save_as_version(value, *args)
    begin
      @auto_versioning_disabled = true
      self.current_version = value
      self.save(*args)
    ensure
      @auto_versioning_disabled = false
    end
  end

  def current_version
    val = self.relationships(:has_model_version).first
    val ? val.to_s : nil
  end

  def current_version=(value)
    self.remove_relationship(:has_model_version, nil)
    if value.present?
      self.add_relationship(:has_model_version, value, true)
    end
    self.rels_ext.serialize!
  end

  alias_method :current_migration, :current_version
  alias_method :current_migration=, :current_version=

end