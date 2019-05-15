# frozen_string_literal: true

class IiifManifestRange
  attr_reader :label, :items

  def initialize(label:, items: [])
    @label = label
    @items = items
  end
end
