# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement

  self.default_processor_chain += [:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :only_published_items, :limit_to_non_hidden_items]#, :apply_sticky_settings]

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"MediaObject"'
  end

  def only_published_items(solr_parameters)
    if current_ability.cannot? :create, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'workflow_published_sim:"Published"'
    end
  end

  def limit_to_non_hidden_items(solr_parameters)
    if current_ability.cannot? :discover_everything, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << [policy_clauses,"(*:* NOT hidden_bsi:true)"].compact.join(" OR ")
    end
  end

  def add_access_controls_to_solr_params_if_not_admin(solr_parameters)
    if current_ability.cannot? :discover_everything, MediaObject
      add_access_controls_to_solr_params(solr_parameters)
    end
  end
end
