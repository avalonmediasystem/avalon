require 'open-uri'
require 'securerandom'
require 'yaml'
require 'json/ld'
require 'rdf/vocab/dc'
require 'rdf/vocab/oa'
require 'rdf/vocab/cnt'
require 'rdf/vocab/dcmitype'
require 'rdf/vocab/foaf'

class RDFAnnotation
  include DocumentLoader

  RDF::Vocab::DC = RDF::DC unless defined?(RDF::Vocab::DC)
  RDF::Vocab::FOAF = RDF::FOAF unless defined?(RDF::Vocab::FOAF)

  # Support reading legacy properties
  RDF::Vocab::OA.property 'annotatedAt'
  RDF::Vocab::OA.property 'annotatedBy'

  attr_reader :graph

  CONTEXT_URI = 'http://www.w3.org/ns/oa.jsonld'.freeze

  def self.from_jsonld(json)
    content = JSON.parse(json)
    self.new(JSON::LD::API.toRDF(content, documentLoader: DocumentLoader.document_loader))
  end

  def to_jsonld(opts = {})
    input = JSON.parse((graph.dump :jsonld, standard_prefixes: true, prefixes: { oa: RDF::Vocab::OA.to_iri.value }))
    frame = YAML.load(File.read(Rails.root.join('lib', 'active_annotations', 'frame.yml')))
    output = JSON::LD::API.frame(input, frame, validate: false, omitDefault: true, documentLoader: DocumentLoader.document_loader)
    graph = output.delete('@graph').try(:first)
    output.merge!(graph) if graph
    if opts[:pretty_json]
      JSON.pretty_generate output
    else
      output.to_json
    end
  end

  def initialize(content = nil)
    @graph = RDF::Graph.new
    if content.nil?
      add_default_content!
    else
      @graph << content
    end
  end

  def get_value(subject, predicate)
    return nil if subject.nil?

    statement = graph.first(subject: subject, predicate: predicate)
    if statement.nil?
      nil
    elsif statement.object.is_a?(RDF::Literal)
      statement.object.object
    else
      statement.object.value
    end
  end

  def set_value(subject, predicate, value)
    return nil if subject.nil?

    @graph.delete({ subject: subject, predicate: predicate })
    @graph << RDF::Statement.new(subject, predicate, value) unless value.nil?
  end

  def add_statements(*statements)
    statements.each { |statement| @graph << statement }
  end

  def add_default_content!
    aid = new_id
    add_statements(
      RDF::Statement.new(aid, RDF.type, RDF::Vocab::OA.Annotation),
      RDF::Statement.new(aid, RDF::Vocab::DC.created, DateTime.now)
    )
  end

  def ensure_body!
    return unless body_id.nil?

    bid = new_id
    add_statements(
      RDF::Statement.new(annotation_id, RDF::Vocab::OA.hasBody, bid),
      RDF::Statement.new(bid, RDF.type, RDF::Vocab::DCMIType.Text),
      RDF::Statement.new(bid, RDF.type, RDF::Vocab::CNT.ContentAsText)
    )
  end

  def ensure_target!
    return unless target_id.nil?

    tid = new_id
    add_statements(
      RDF::Statement.new(annotation_id, RDF::Vocab::OA.hasTarget, tid),
      RDF::Statement.new(tid, RDF.type, RDF::Vocab::OA.SpecificResource)
    )
  end

  def ensure_selector!
    return unless selector_id.nil?

    ensure_target!
    sid = new_id
    add_statements(
      RDF::Statement.new(target_id, RDF::Vocab::OA.hasSelector, sid),
      RDF::Statement.new(sid, RDF.type, RDF::Vocab::OA.FragmentSelector),
      RDF::Statement.new(sid, RDF::Vocab::DC.conformsTo, RDF::URI('http://www.w3.org/TR/media-frags/'))
    )
  end

  def new_id
    RDF::URI.new("urn:uuid:#{SecureRandom.uuid}")
  end

  def find_id(type)
    statement = @graph.first(predicate: RDF.type, object: type)
    statement&.subject
  end

  def annotation_id
    find_id(RDF::Vocab::OA.Annotation)
  end

  def body_id
    statement = @graph.first(subject: annotation_id, predicate: RDF::Vocab::OA.hasBody)
    statement&.object
  end

  def target_id
    find_id(RDF::Vocab::OA.SpecificResource)
  end

  def selector_id
    find_id(RDF::Vocab::OA.FragmentSelector)
  end

  def fragment_value
    graph.first(subject: selector_id, predicate: RDF.value)
  end

  def fragment_value=(value)
    ensure_selector!
    set_value(selector_id, RDF.value, value)
  end

  def start_time
    value = fragment_value.nil? ? nil : fragment_value.object.value.scan(/^t=(.*)$/).flatten.first.split(/,/)[0]
    Float(value)
  rescue
    value
  end

  def start_time=(value)
    self.fragment_value = "t=#{[value, end_time].join(',')}"
  end

  def end_time
    value = fragment_value.nil? ? nil : fragment_value.object.value.scan(/^t=(.*)$/).flatten.first.split(/,/)[1]
    Float(value)
  rescue
    value
  end

  def end_time=(value)
    self.fragment_value = "t=#{[start_time, value].join(',')}"
  end

  def content
    get_value(body_id, RDF::Vocab::CNT.chars)
  end

  def content=(value)
    ensure_body!
    set_value(body_id, RDF::Vocab::CNT.chars, value)
  end

  def annotated_by
    get_value(annotation_id, RDF::Vocab::DC.creator) || get_value(annotation_id, RDF::Vocab::OA.annotatedBy)
  end

  def annotated_by=(value)   
    @graph.delete({ subject: RDF::URI(annotated_by) }) unless annotated_by.nil?

    value = value.nil? ? nil : RDF::URI(value)
    set_value(annotation_id, RDF::Vocab::DC.creator, value)
    set_value(value, RDF.type, RDF::Vocab::FOAF.Person)
  end

  def annotated_at
    get_value(annotation_id, RDF::Vocab::DC.modified) || get_value(annotation_id, RDF::Vocab::OA.annotatedAt)
  end

  def annotated_at=(value)
    set_value(annotation_id, RDF::Vocab::DC.modified, value)
  end

  def source
    # TODO: Replace this with some way of retrieving the actual source
    get_value(target_id, RDF::Vocab::OA.hasSource)
  end

  def source=(value)
    unless target_id.nil?
      statement = @graph.first(subject: target_id, predicate: RDF::Vocab::OA.hasSource)
      @graph.delete({ subject: statement.object, predicate: RDF.type }) unless statement.nil?
      @graph.delete({ subject: target_id, predicate: RDF::Vocab::OA.hasSource })
    end

    return if value.nil?

    ensure_target!
    add_statements(
      RDF::Statement.new(target_id, RDF::Vocab::OA.hasSource, RDF::URI(value.rdf_uri)),
      RDF::Statement.new(RDF::URI(value.rdf_uri), RDF.type, value.rdf_type)
    )
  end

  def label
    get_value(annotation_id, RDF::RDFS.label)
  end

  def label=(value)
    set_value(annotation_id, RDF::RDFS.label, value)
  end
end
