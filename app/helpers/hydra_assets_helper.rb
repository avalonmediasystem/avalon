module HydraAssetsHelper
  include Hydra::HydraAssetsHelperBehavior

  # Create a link for creating a new asset of the specified content_type
  # If user is not logged in, the link leads to the login page with appropriate redirect params for creating the asset after logging in
  # @param [String] link_label for the link
  # @param [String] content_type
  def link_to_create_asset(link_label, content_type)
    if current_user
      link_to link_label, {:action => 'new', :controller => "/assets", :content_type => content_type}, :class=>"create_asset"
    else
      link_to link_label, new_user_session_path(:redirect_params => {:action => "new", :controller=> "/assets", :content_type => content_type}), :class=>"create_asset"
    end
  end
end
