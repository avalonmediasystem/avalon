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

class CheckoutsController < ApplicationController
  before_action :set_checkout, only: %i[show update destroy]
  before_action :set_checkouts, only: %i[index return_all]
  load_and_authorize_resource except: [:create]

  # GET /checkouts or /checkouts.json
  def index
    respond_to do |format|
      format.html { render :index }
      format.json do
        response = {
          "data": @checkouts.collect do |checkout|
            if current_ability.is_administrator?
              admin_array(checkout)
            else
              user_array(checkout)
            end
          end.compact,
          "recordsTotal": @checkouts.count
        }
        render json: response
      end
    end
  end

  # GET /checkouts/1.json
  def show; end

  # POST /checkouts or /checkouts.json
  def create
    @checkout = Checkout.new(user: current_user, media_object_id: checkout_params[:media_object_id])

    respond_to do |format|
      # TODO: move this can? check into a checkout ability (can?(:create, @checkout))
      if can?(:create, @checkout) && @checkout.save
        format.html { redirect_to media_object_path(checkout_params[:media_object_id]) }
        format.json { render :show, status: :created, location: @checkout }
      else
        format.json { render json: @checkout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /checkouts/1.json
  def update
    respond_to do |format|
      if @checkout.update(checkout_params.slice(:return_time))
        # TODO: Change this since it will be called from the media object show page
        format.json { render :show, status: :ok, location: @checkout }
      else
        format.json { render json: @checkout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /checkouts/1/return
  def return
    @checkout.update(return_time: DateTime.current)

    respond_to do |format|
      format.html { redirect_back fallback_location: checkouts_url }
      format.json { head :no_content }
    end
  end

  # PATCH /checkouts/return_all
  def return_all
    @checkouts.each { |c| c.update(return_time: DateTime.current) }

    respond_to do |format|
      format.html { redirect_to checkouts_url }
      format.json { head :no_content }
    end
  end

  # DELETE /checkouts/1 or /checkouts/1.json
  def destroy
    @checkout.destroy
    flash[:notice] = "Checkout was successfully destroyed."

    respond_to do |format|
      format.html { redirect_to checkouts_url, notice: flash[:notice] }
      format.json { render json: flash[:notice] }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_checkout
      @checkout = Checkout.find(params[:id])
    end

    def set_checkouts
      if params[:display_returned] == 'true'
        @checkouts = if current_ability.is_administrator?
                       set_active_checkouts.or(Checkout.all.where("return_time <= now()"))
                     else
                       set_active_checkouts.or(Checkout.returned_for_user(current_user&.id))
                     end
      else
        @checkouts = set_active_checkouts
      end
    end

    def set_active_checkouts
      @checkouts = if current_ability.is_administrator?
                     Checkout.all.where("return_time > now()")
                   else
                     Checkout.active_for_user(current_user&.id)
                   end
    end

    def admin_array(checkout)
      checkout_array = user_array(checkout)
      checkout_array.present? ? [checkout.user.user_key] + checkout_array : nil
    end

    def user_array(checkout)
      [
        view_context.link_to(checkout.media_object.title, main_app.media_object_url(checkout.media_object)),
        "<span data-utc-time='#{checkout.checkout_time.iso8601}' />",
        "<span data-utc-time='#{checkout.return_time.iso8601}' />",
        time_remaining(checkout),
        checkout_actions(checkout)
      ]
    rescue ActiveFedora::ObjectNotFoundError
      nil
    end

    def time_remaining(checkout)
      if checkout.return_time > DateTime.current
        view_context.distance_of_time_in_words(checkout.return_time - DateTime.current)
      else
        "-"
      end
    end

    def checkout_actions(checkout)
      return '' unless checkout.return_time > DateTime.current
      view_context.link_to('Return', return_checkout_url(checkout), class: 'btn btn-outline btn-xs', method: :patch)
    end

    # Only allow a list of trusted parameters through.
    def checkout_params
      params.require(:checkout).permit(:media_object_id, :return_time, :display_returned)
    end
end
