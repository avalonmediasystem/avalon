class FacetGroupComponent < Blacklight::Response::FacetGroupComponent
  def render?
    body.to_s.present?
  end
end
