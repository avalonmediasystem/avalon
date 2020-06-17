# frozen_string_literal: true
require 'singleton'

module Avalon
  class ElasticTranscoder
    include Singleton
    attr_reader :etclient

    def initialize
      @etclient = Aws::ElasticTranscoder::Client.new
    end

    def find_preset(container, format, quality)
      container_description = container == 'ts' ? 'hls' : container
      key = "avalon-#{format}-#{quality}-#{container_description}"
      find_preset_by_name(key)
    end

    def find_preset_by_name(key)
      Rails.cache.fetch("transcoder-preset-for-#{key}") do
        next_token = nil
        result = nil
        loop do
          resp = @etclient.list_presets page_token: next_token
          result = resp.presets.find { |p| p.name == key }
          next_token = resp.next_page_token
          break if result.present? || next_token.nil?
        end
        result
      end
    end

    def create_preset(template)
      @etclient.create_preset(template)
    end

    def read_templates(path)
      templates = YAML.load(File.read(path))
      temp = [:audio, :video].product([:low, :medium, :high], ['ts', 'mp4']).collect do |format, quality, container|
        next unless templates[:settings][format][quality].present?
        template = templates[:templates][format].deep_dup.deep_merge(templates[:settings][format][quality])
        container_description = container == 'ts' ? 'hls' : container
        template.merge!(
          name: "avalon-#{format}-#{quality}-#{container_description}",
          description: "Avalon Media System: #{format}/#{quality}/#{container_description}",
          container: container
        )
        template
      end
      temp.reject { |e| e.to_s.empty? }
    end
  end
end
