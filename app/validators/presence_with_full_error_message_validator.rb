class PresenceWithFullErrorMessageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "The #{attribute.to_s.humanize.downcase} field is required." unless value.present?
  end
end