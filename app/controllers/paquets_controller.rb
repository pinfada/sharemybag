class PaquetsController < ApplicationController
  before_action :search
  before_action :set_paquet, only: [:show, :edit, :update, :destroy]

  # GET /paquets
  # GET /paquets.json
  def index
    @paquets = Paquet.all
  end

  # GET /paquets/1
  # GET /paquets/1.json
  def show
  end

  # GET /paquets/new
  def new
    @paquet = Paquet.new
  end

  # GET /paquets/1/edit
  def edit
  end

  # POST /paquets
  # POST /paquets.json
  def create
    @paquet = Paquet.new(paquet_params)
    if @paquet.save
			# permet de recuperer les infos bagages de l'utilisateur
			@identifiant = Bagage.where(user_id: current_user.id).pluck(:id)
			@paquet.update_attributes(:bagage_id => @identifiant.pop, :user_id => current_user.id)
			flash[:success] = "Paquet ajouté avec succes!"
			redirect_to root_path
    else
      render :new
    end
  end

  # PATCH/PUT /paquets/1
  # PATCH/PUT /paquets/1.json
  def update
    respond_to do |format|
      if @paquet.update(paquet_params)
        format.html { redirect_to @paquet, notice: 'Paquet was successfully updated.' }
        format.json { render :show, status: :ok, location: @paquet }
      else
        format.html { render :edit }
        format.json { render json: @paquet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /paquets/1
  # DELETE /paquets/1.json
  def destroy
    @paquet.destroy
    respond_to do |format|
      format.html { redirect_to paquets_url, notice: 'Paquet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_paquet
      @paquet = Paquet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def paquet_params
      params.require(:paquet).permit(:poids, :prix, :longueur, :largeur, :hauteur, :booking_id, :user_id)
    end
end
