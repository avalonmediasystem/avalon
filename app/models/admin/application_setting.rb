class Admin::ApplicationSetting < ApplicationRecord
  include AttrJson::Record
  include AttrJson::NestedAttributes
  include NestedAppSetting

  attr_json_config(default_container_attribute: :options)
  # We have many more nested attributes than single layer, so have the default be accept nested
  attr_json_config(default_accepts_nested_attributes: { reject_if: :all_blank })
  validates :singleton_guard, inclusion: [0]

  # First level settings, disable accepts_nested_attributes for each one
  attr_json :name, :string, default: "Avalon Media System", accepts_nested_attributes: false
  attr_json :google_analytics_tracking_id, :string, accepts_nested_attributes: false
  attr_json :repository_read_only_mode, :boolean, default: false, accepts_nested_attributes: false
  attr_json :repository_read_only_mode_message, :string, default: "🚧 Read-only mode: all content editing has been disabled 🚧", accepts_nested_attributes: false
  attr_json :bib_retriever, ActiveModel::Type::Value.new, default: -> { bib_retriever_default }
  attr_json :intercom, ActiveModel::Type::Value.new, default: -> { intercom_default }

  # Nested settings
  attr_json :accessibility_compliance, AccessibilityCompliance.to_type, default: -> { AccessibilityCompliance.new } 
  attr_json :caption_default, CaptionDefault.to_type, default: -> { CaptionDefault.new }
  attr_json :controlled_digital_lending, ControlledDigitalLending.to_type, default: -> { ControlledDigitalLending.new }
  attr_json :email, Email.to_type, default: -> { Email.new }
  attr_json :flash_message, ApplicationFlashMessage.to_type, default: -> { ApplicationFlashMessage.new }
  attr_json :home_page, HomePage.to_type, default: -> { HomePage.new }
  attr_json :master_file_management, MasterFileManagement.to_type, default: -> { MasterFileManagement.new }
  attr_json :recaptcha, Recaptcha.to_type, default: -> { Recaptcha.new }
  attr_json :supplemental_files, SupplementalFilesProxy.to_type, default: -> { SupplementalFilesProxy.new }
  attr_json :waveform, Waveform.to_type, default: -> { Waveform.new }

  encrypts :options

  class << self
    def instance
      where(singleton_guard: 0).first_or_create!
    end

    private

    def bib_retriever_default
      {
        default: {
          protocol: 'sru',
          url: 'http://zgate.library.example.edu:9000/catdb',
          query: 'rec.id=%{bib_id}',
          namespace: nil,
          retriever_class: 'Avalon::BibRetriever::SRU',
          retriever_class_require: 'avalon/bib_retriever/sru'
        }
      }
    end

    def intercom_default
      {
        default: {
          url: nil,
          api_token: nil,
          import_bib_record: true,
          publish: false,
          remove_identifiers: false,
          push_label: nil
        }
      }
    end
  end

  private

  def method_missing(name, *_args, **_kwargs, &_block)
    if Settings.respond_to?(name)
      # TODO: Try to save setting for gradual migration ala hyrax fedora->valkyrie transition?
      Settings.public_send(name)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    Settings.respond_to?(name) || super
  end
end
