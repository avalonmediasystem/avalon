# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
    build_omniauth_form do |form|
      render html: form.html_safe, layout: true
    end
  end

  def render_form_with_errors
    add_errors_to_flash
    build_omniauth_form do |form|
      render html: form.html_safe, layout: true
    end
  end

  private

    def add_errors_to_flash
      model = request.env["omniauth.#{strategy.name}"]
      flash[:error] = model.errors.to_a
    end

    def strategy
      strategy_name = request.class.provider
      opts = Devise.omniauth_configs[strategy_name].options
      strategy_class = Devise.omniauth_configs[strategy_name].strategy_class
      strategy_class.new(opts)
    end

    def build_omniauth_form
      html = strategy.send(request.class.phase).last.body.first.strip
      doc = Nokogiri::HTML(html)
      form = doc.at_xpath('//form')
      form.xpath('label|input').to_a.in_groups_of(2).each do |label, input|
        input['class'] = 'form-control'
        label.replace('<div class="form-group"/>').first.add_child(label).add_next_sibling(input)
      end
      form.at_xpath('//input[last()]').add_next_sibling view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token) 
      form.xpath('button').each { |btn| btn['class'] = 'btn btn-primary' }
      yield(%{<div class="omniauth-form container">#{form.to_html}</div>})
    end
end
