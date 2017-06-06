require 'fedora-migrate'

FedoraMigrate::ContentMover.class_eval do
    def move_content
      target.content = StringIO.new(source.content)
      # Comment out the next line assuming that we are setting it explicitly on target before getting here
      # target.original_name = source.label.try(:gsub, /"/, '\"')
      target.mime_type = source.mimeType
      save
      report.error = "Failed checksum" unless valid?
    end
end
