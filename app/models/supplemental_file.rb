class SupplementalFile < ApplicationRecord
  has_one_attached :file

  def attach_file(new_file)
    file.attach(new_file)
    self.label = file.filename.to_s if label.blank?
  end
end
