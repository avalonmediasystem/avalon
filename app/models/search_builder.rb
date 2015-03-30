class SearchBuilder < Hydra::SearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"info:fedora/afmodel:MediaObject"'
  end

  def only_published_items(solr_parameters)
    if current_ability.cannot? :create, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'workflow_published_sim:"Published"'
    end
  end

  def limit_to_non_hidden_items(solr_parameters)
    if current_ability.cannot? :create, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << '!hidden_bsi:true'
    end
    end

  def add_access_controls_to_solr_params_if_not_admin(solr_parameters)
    if current_ability.cannot? :discover_everything, MediaObject
      add_access_controls_to_solr_params(solr_parameters)
    end
  end 
end
