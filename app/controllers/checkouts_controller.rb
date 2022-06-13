class CheckoutsController < ApplicationController
  before_action :set_checkout, only: %i[show update destroy]
  before_action :set_checkouts, only: %i[index return_all]
  load_and_authorize_resource except: [:create]

  # GET /checkouts or /checkouts.json
  def index
    @checkouts
  end

  # GET /checkouts/1.json
  def show
  end

  # POST /checkouts.json
  def create
    @checkout = Checkout.new(user: current_user, media_object_id: checkout_params[:media_object_id], checkout_time: DateTime.current, return_time: DateTime.current + 2.weeks)

    respond_to do |format|
      # TODO: move this can? check into a checkout ability (can?(:create, @checkout))
      if can?(:create, @checkout) && @checkout.save
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

  # DELETE /checkouts/1 or /checkouts/1.json
  def destroy
    @checkout.destroy

    respond_to do |format|
      format.html { redirect_to checkouts_url, notice: "Checkout was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # DELETE /checkouts
  def destroy_all
    @checkouts.destroy_all

    respond_to do |format|
      format.html { redirect_to checkouts_url, notice: "Checkouts were sucessfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_checkout
      @checkout = Checkout.find(params[:id])
    end

    def set_checkouts
      @checkouts = if current_ability.is_administrator?
                     Checkout.all.where("return_time > now()")
                   else
                     Checkout.active_for_user(current_user.id)
                   end
    end

    # Only allow a list of trusted parameters through.
    def checkout_params
      params.require(:checkout).permit(:media_object_id, :return_time)
    end
end
