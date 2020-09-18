# frozen_string_literal: true

namespace :avalon do
  namespace :aws do
    task create_presets: :environment do
      require 'aws-sdk-elastictranscoder'

      et = Avalon::ElasticTranscoder.instance
      templates = et.read_templates(Rails.root.join(Settings.encoding.presets_path))
      templates.each do |template|
        unless et.find_preset_by_name(template[:name]).present?
          resp = et.create_preset(template)
          Rails.logger.info "#{template[:name]}: #{resp.preset.id}"
        end
      end
    end
  end
end
