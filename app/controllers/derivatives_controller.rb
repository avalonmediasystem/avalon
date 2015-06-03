# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'net/http/digest_auth'

class DerivativesController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:authorize]

  # Validate if the session is active, the user is correct, and that they
  # have permission to stream the derivative based on the session_id and
  # the path to the stream.
  #
  # The values should be put into a POST. The method will reject a GET
  # request for security reasons
  def authorize
    begin
      resp = { :authorized => StreamToken.validate_token(params[:token]) }
      
      respond_to do |format|
        format.urlencoded { resp[:authorized] = resp[:authorized].join(';'); render :text => resp.to_query, :content_type => :urlencoded, :status => :accepted }
        format.text       { render :text => resp[:authorized].join("\n"), :status => :accepted }
        format.xml        { render :xml  => resp, :root => :response, :status => :accepted }
        format.json       { render :json => resp, :status => :accepted }
      end
    rescue StreamToken::Unauthorized
      return head :forbidden 
    end
  end
end
