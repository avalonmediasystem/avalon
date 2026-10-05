module NestedAppSetting
  class JsonModel
    include AttrJson::Model
    include AttrJson::NestedAttributes
  end

  # Second level of nesting. These have to come first because the
  # class has to exist to be referenced in the higher nesting level.

  # Email
  class EmailConfig < JsonModel
    attr_json :address, :string, default: "mail-relay.iu.edu"
    attr_json :port, :integer, default: 587
    attr_json :enable_starttls_auto, :boolean, default: false
  end

  # Recaptcha
  class Recaptcha3 < JsonModel
    attr_json :action, :string, default: 'comment'
    attr_json :minimum_score, :float, default: 0.5
  end

  # Top level of nesting
  class AccessibilityCompliance < JsonModel
    attr_json :enforce, :boolean, default: false
    attr_json :compliance_date, :datetime, default: Date.edtf('2026-04-24')
  end

  class ApplicationFlashMessage < JsonModel
    attr_json :type, :string, default: 'off'
    attr_json :message, :string

    validates :type, inclusion: { in: ['success', 'notice', 'error', 'alert', 'off'] }
  end

  class CaptionDefault < JsonModel
    attr_json :language, :string, default: 'eng'
    attr_json :name, :string, default: 'English'

    validate :validate_language

    private

    def validate_language
      LanguageTerm.find(self.language)
    rescue
      errors.add(:base, "Language must be a valid ISO 639-2 language code")
    end
  end

  class ControlledDigitalLending < JsonModel
    attr_json :enable, :boolean, default: false
    attr_json :collections_enabled, :boolean, default: false
    attr_json :default_lending_period, :string, default: 'P14D'
  end

  class Email < JsonModel
    attr_json :comments, :string
    attr_json :notification, :string
    attr_json :support, :string
    attr_json :mailer, :string, default: 'smtp'
    attr_json :accessibility_request_link, :string
    attr_json :config, EmailConfig.to_type, default: -> { EmailConfig.new }
  end

  class HomePage < JsonModel
    attr_json :featured_collections, :string, array: true
    attr_json :carousel_collections, :string, array: true
  end

  class MasterFileManagement < JsonModel
    attr_json :strategy, :string, default: 'move'
    attr_json :path, :string, default: 's3://preserves/'

    validates :strategy, inclusion: { in: ['move', 'delete', 'none'] }
  end

  class Recaptcha < JsonModel
    attr_json :site_key, :string
    attr_json :secret_key, :string
    attr_json :type, :string, default: 'v2_checkbox'
    attr_json :v3, Recaptcha3.to_type, default: -> { Recaptcha3.new }

    validates :type, inclusion: { in: ['v2_checkbox', 'v3'] }
  end

  class SupplementalFilesProxy < JsonModel
    attr_json :proxy, :boolean, default: false
  end

  class Waveform < JsonModel
    attr_json :player_width, :integer, default: 1200
    attr_json :finest_zoom, :integer, default: 5
    attr_json :sample_rate, :integer, default: 41_000
  end
end
