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
        format.urlencoded { render :text => resp.to_query, :content_type => :urlencoded, :status => :accepted }
        format.text       { render :text => resp[:authorized], :status => :accepted }
        format.xml        { render :xml  => resp, :root => :response, :status => :accepted }
        format.json       { render :json => resp, :status => :accepted }
      end
    rescue StreamToken::Unauthorized
      return head :forbidden 
    end
  end
end
