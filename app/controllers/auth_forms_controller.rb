# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  skip_before_action :verify_authenticity_token, only: [:render_form_with_errors]

  def render_identity_request_form
    render html: omniauth_form(:identity, :request_phase).html_safe, layout: true
  end

  def render_identity_registration_form
    render html: omniauth_form(:identity, :registration_form).html_safe, layout: true
  end

  def render_form_with_errors
    add_errors_to_flash
    render html: omniauth_form(:identity, :registration_form).html_safe, layout: true
  end

  private
    def add_errors_to_flash
      model = request.env["omniauth.identity"]
      flash[:error] = model.errors.to_a
    end

    def omniauth_form(strategy_name, phase=:request_phase)
      opts = Devise.omniauth_configs[strategy_name].options
      strategy_class = Devise.omniauth_configs[strategy_name].strategy_class
      strategy = strategy_class.new(opts)
      html = strategy.send(phase).last.first.strip
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
