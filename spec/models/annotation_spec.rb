require 'rails_helper'
require 'erb'

describe Annotation do
  subject { Annotation.create }
  let!(:start_time) { Faker::Number.positive }
  let!(:end_time) { Faker::Number.positive(from: start_time) }
  let!(:content) { Faker::Hipster.paragraph }
  let!(:annotated_by) { Faker::Internet.url }
  let!(:annotated_at) do
    value = DateTime.parse(Faker::Time.backward(days: 30).iso8601)
    RDF::VERSION::MAJOR < '2' ? value.utc : value
  end
  let!(:source) { Faker::Internet.url }
  let!(:label) { Faker::Hipster.sentence }
  let!(:source_obj) { OpenStruct.new rdf_uri: source, rdf_type: RDF::Vocab::DCMIType.MovingImage }

  it "is an Annotation" do
    expect(subject).to be_a(Annotation)
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:master_file) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:start_time) }
  end

  it "#inspect" do
    expect(subject.inspect).to be_a(String)
  end

  describe "accessors" do
    it "start_time" do
      subject.start_time = start_time
      expect(subject.start_time).to eq(start_time)
      subject.start_time = nil
      expect(subject.start_time).to be_nil
    end

    it "end_time" do
      subject.end_time = end_time
      expect(subject.end_time).to eq(end_time)
      subject.end_time = nil
      expect(subject.end_time).to be_nil
    end

    it "content" do
      subject.content = content
      expect(subject.content).to eq(content)
      subject.content = nil
      expect(subject.content).to be_nil
    end

    it "annotated_by" do
      subject.annotated_by = annotated_by
      expect(subject.annotated_by).to eq(annotated_by)
      subject.annotated_by = nil
      expect(subject.annotated_by).to be_nil
    end

    it "annotated_at" do
      subject.annotated_at = annotated_at
      expect(subject.annotated_at).to eq(annotated_at)
      subject.annotated_at = nil
      expect(subject.annotated_at).to be_nil
    end

    it "source" do
      subject.source = source_obj
      expect(subject.source).to eq(source)
      subject.source = nil
      expect(subject.source).to be_nil
    end

    it "label" do
      subject.label = label
      expect(subject.label).to eq(label)
      subject.label = nil
      expect(subject.label).to be_nil
    end
  end

  describe "read-only attributes" do
    it "source_uri" do
      subject.source = source_obj
      expect(subject.source_uri).to eq(subject.source)
      expect { subject.source_uri = 'foo' }.to raise_error(NoMethodError)
    end

    it "uuid" do
      expect(subject.uuid).to eq(subject.internal.annotation_id.value)
      expect { subject.uuid = 'foo' }.to raise_error(NoMethodError)
    end

    it "annotation" do
      expect { subject.annotation = 'foo' }.to raise_error(NoMethodError)
    end
  end

  describe "persistence" do
    before do
      subject.start_time = start_time
      subject.end_time = end_time
      subject.content = content
      subject.annotated_by = annotated_by
      subject.annotated_at = annotated_at
      subject.source = source_obj
      subject.label = label
      subject.master_file = FactoryBot.create(:master_file)
      subject.save
    end

    let!(:new_copy) { Annotation.find_by(uuid: subject.uuid) }
    let!(:graph) { RDF::Graph.new << JSON::LD::API.toRDF(JSON.parse(subject.annotation), documentLoader: DocumentLoader.document_loader) }

    it "serialize" do
      expect(graph).to be_valid
    end

    it "pretty-print" do
      expect(new_copy.pretty_annotation).to eq(subject.pretty_annotation)
    end

    it "load" do
      expect(new_copy.start_time).to eq(subject.start_time)
      expect(new_copy.end_time).to eq(subject.end_time)
      expect(new_copy.content).to eq(subject.content)
      expect(new_copy.annotated_by).to eq(subject.annotated_by)
      expect(new_copy.annotated_at).to eq(subject.annotated_at)
      expect(new_copy.source).to eq(subject.source)
      expect(new_copy.label).to eq(subject.label)
    end
  end
end
