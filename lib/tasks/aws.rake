# frozen_string_literal: true

namespace :avalon do
  namespace :aws do
    task create_presets: :environment do
      require 'aws-sdk'

      et = Avalon::ElasticTranscoder.instance
      templates = et.read_templates(Rails.root.join('config', 'encoding_presets.yml'))
      templates.each do |template|
        unless et.find_preset_by_name(template[:name]).present?
          preset = et.create_preset(template)
          Rails.logger.info "#{template[:name]}: #{preset.id}"
        end
      end
    end
  end
end
