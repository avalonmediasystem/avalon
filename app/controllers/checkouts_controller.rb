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
    @checkout = Checkout.new(user: current_user, media_object_id: checkout_params[:media_object_id])

    respond_to do |format|
      # TODO: move this can? check into a checkout ability (can?(:create, @checkout))
      if can?(:create, @checkout) && @checkout.save
        format.html { redirect_to media_object_path(checkout_params[:media_object_id]), flash: { success: "Checkout was successfully created."} }
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

  #PATCH /checkouts/1/return
  def return
    @checkout.update(return_time: DateTime.current)

    flash[:notice] = "Checkout was successfully returned."
    respond_to do |format|
      format.html { redirect_back fallback_location: checkouts_url, notice: flash[:notice] }
      format.json { render json:flash[:notice] }
    end
  end


  # PATCH /checkouts/return_all
  def return_all
    @checkouts.each { |c| c.update(return_time: DateTime.current) }

    respond_to do |format|
      format.html { redirect_to checkouts_url, notice: "All checkouts were successfully returned." }
      format.json { head :no_content }
    end
  end

  # GET /checkouts/display_returned.json
  def display_returned
    if current_ability.is_administrator?
      @checkouts = @checkouts.or(Checkout.all.where("return_time <= now()"))
    else
      @checkouts = @checkouts.or(Checkout.returned_for_user(current_user.id))
    end
  end

  # DELETE /checkouts/1 or /checkouts/1.json
  def destroy
    @checkout.destroy
    flash[:notice] = "Checkout was successfully destroyed."
    respond_to do |format|
      format.html { redirect_to checkouts_url, notice: flash[:notice] }
      format.json { render json:flash[:notice] }
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
