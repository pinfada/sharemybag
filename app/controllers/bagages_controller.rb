class BagagesController < ApplicationController
  before_action :signed_in_user
  before_action :search
  before_action :set_bagage, only: [:show, :edit, :update, :destroy]

  # GET /bagages
  # GET /bagages.json
  def index
    @bagages = Bagage.paginate(page: params[:page], :per_page => 30)
  end

  # GET /bagages/1
  # GET /bagages/1.json
  def show
  end

  # GET /bagages/new
  def new
    @bagage = current_user.bagages.new
    @vol  = Vol.find(params[:vol_id]) unless params[:vol_id].nil?
    redirect_to vols_path if params[:vol_id].nil?
    params[:bagages].to_i.times { current_user.bagages.build }
  end

  # GET /bagages/1/edit
  def edit
  end

  # POST /bagages
  # POST /bagages.json
  def create
    @bagage = current_user.bagages.create(bagage_params)
    if @bagage.save
      current_user.update_attribute(:vol_id, params[:vol_id])
      redirect_to new_booking_path
    else
      render :new
    end
  end

  # PATCH/PUT /bagages/1
  # PATCH/PUT /bagages/1.json
  def update
    respond_to do |format|
      if @bagage.update(bagage_params)
        format.html { redirect_to @bagage, notice: 'bagage was successfully updated.' }
        format.json { render :show, status: :ok, location: @bagage }
      else
        format.html { render :edit }
        format.json { render json: @bagage.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bagages/1
  # DELETE /bagages/1.json
  def destroy
    @bagage.destroy
    respond_to do |format|
      format.html { redirect_to bagages_url, notice: 'bagage was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bagage
      @bagage = current_user.bagages.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bagage_params
      params.require(:bagage).permit(:poids, :prix, :longueur, :largeur, :hauteur, :user_id, :bagage_id)
    end
end
