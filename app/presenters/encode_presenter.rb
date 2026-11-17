# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# Generated via
#  `rails generate hyrax:work AudiovisualWork`

class EncodePresenter
  include ActionView::Helpers::NumberHelper

  attr_reader :encode_record

  def initialize(encode_record)
    @encode_record = encode_record
  end

  delegate :id, :adapter, :display_title, :master_file_id, :media_object_id, :created_at, :progress, to: :encode_record

  def status
    @encode_record.state&.capitalize
  end

  def global_id
    @encode_record.global_id.split('/').last
  end

  def title
    @encode_record.title.split('/').last
  end

  def master_file_url
    master_file_id.present? ? Rails.application.routes.url_helpers.master_file_path(master_file_id) : ''
  end

  def media_object_url
    media_object_id.present? ? Rails.application.routes.url_helpers.media_object_path(media_object_id) : ''
  end

  def started
    DateTime.parse(raw_object_parsed["created_at"]).utc.strftime('%D %r')
  end

  def ended
    DateTime.parse(raw_object_parsed["updated_at"]).utc.strftime('%D %r')
  end

  def raw_object
    JSON.pretty_generate(raw_object_parsed)
  end

  def raw_object_parsed
    @raw_object_parsed ||= @encode_record&.raw_object.present? ? JSON.parse(@encode_record.raw_object) : {}
  rescue
    {}
  end

  def create_options
    JSON.pretty_generate(create_options_parsed)
  end

  def create_options_parsed
    @create_options_parsed = @encode_record&.create_options.present? ? JSON.parse(@encode_record.create_options) : {}
  rescue
    {}
  end

  def errors
    raw_object_parsed["errors"]
  end
end
