class CheckoutsController < ApplicationController
  before_action :set_checkout, only: %i[show update destroy]
  before_action :set_checkouts, only: %i[index return_all]
  load_and_authorize_resource except: [:create]

  # GET /checkouts or /checkouts.json
  def index
    @checkouts

    respond_to do |format|
      format.html { render :index }
      format.json do
        response = {
          "data": @checkouts.collect do |checkout|
            if current_ability.is_administrator?
              index_array(checkout)
            else
              user_array(index_array(checkout))
            end
          end
        }
        render json: response
      end
    end
  end

  # GET /checkouts/1.json
  def show
  end

  # POST /checkouts or /checkouts.json
  def create
    @checkout = Checkout.new(user: current_user, media_object_id: checkout_params[:media_object_id])

    respond_to do |format|
      # TODO: move this can? check into a checkout ability (can?(:create, @checkout))
      if can?(:create, @checkout) && @checkout.save
        format.html { redirect_back fallback_location: checkouts_url, notice: "Item has been successfully checked out."}
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

    respond_to do |format|
      format.html { redirect_back fallback_location: checkouts_url, notice: "Checkout was successfully returned." }
      format.json { head :no_content }
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

    response = {
      "data": @checkouts.collect do |checkout|
        if current_ability.is_administrator?
          index_array(checkout)
        else
          user_array(index_array(checkout))
        end
      end
    }

    respond_to do |format|
      format.json do
        render json: response
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

    def index_array(checkout)
      [
        checkout.user.user_key,
        view_context.link_to(checkout.media_object.title, main_app.media_object_url(checkout.media_object)),
        checkout.checkout_time.to_s(:long_ordinal),
        checkout.return_time.to_s(:long_ordinal),
        if checkout.return_time > DateTime.current
          view_context.distance_of_time_in_words(checkout.return_time - DateTime.current)
        else
          "-"
        end,
        if checkout.return_time > DateTime.current
          view_context.link_to('Return', return_checkout_url(checkout), class: 'btn btn-danger btn-xs', method: :patch, data: { confirm: "Are you sure you want to return this item?" })
        elsif checkout.return_time < DateTime.current && checkout.media_object.lending_status == 'available'
          view_context.link_to('Checkout', checkouts_url(params: { checkout: { media_object_id: checkout.media_object_id }, format: :json }), class: 'btn btn-primary btn-xs', method: :post)
        else
          'Item Unavailable'
        end
      ]
    end

    def user_array(array)
      array.shift
      array
    end

    # Only allow a list of trusted parameters through.
    def checkout_params
      params.require(:checkout).permit(:media_object_id, :return_time)
    end
end