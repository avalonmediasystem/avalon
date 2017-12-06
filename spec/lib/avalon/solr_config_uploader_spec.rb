# Taken from https://raw.githubusercontent.com/samvera-labs/hyku/master/spec/services/solr_config_uploader_spec.rb
require 'rails_helper'
require 'avalon/solr_config_uploader'

RSpec.describe Avalon::SolrConfigUploader, :skip => true do
  let(:config_dir) { Rails.root.join('solr', 'config') }
  subject { described_class.new('solr_config_uploader_test') }

  describe 'round-tripping data to zookeeper' do
    before do
      subject.delete_all
    end

    it 'creates a path in zookeeper' do
      expect { subject.get('schema.xml') }.to raise_error ZK::Exceptions::NoNode

      subject.upload(config_dir)

      expect(subject.get('schema.xml')).not_to be_blank
    end
  end
end
