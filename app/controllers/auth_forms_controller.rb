class AuthFormsController < ApplicationController
  def self.dispatcher(provider, phase)
    klass = Class.new(ActionDispatch::Request) do
      class_attribute :provider
      class_attribute :phase
    end
    klass.provider = provider
    klass.phase = phase
    klass
  end
  
  def render_form
    render html: omniauth_form(request.class.provider, request.class.phase).html_safe, layout: true
  end
  
  private
  def omniauth_form(strategy_name, phase=:request_phase)
    opts = Devise.omniauth_configs[strategy_name].options
    strategy_class = Devise.omniauth_configs[strategy_name].strategy_class
    strategy = strategy_class.new(opts)
    html = strategy.send(phase).last.body.first.strip
    doc = Nokogiri::HTML(html)
    form = doc.at_xpath('//form')
    form.xpath('label|input').to_a.in_groups_of(2).each do |label, input|
      input['class'] = 'form-control'
      label.replace('<div class="form-group"/>').first.add_child(label).add_next_sibling(input)
    end
    form.xpath('button').each { |btn| btn['class'] = 'btn btn-primary' }
    %{<div class="omniauth-form container">#{form.to_html}</div>}
  end
end
