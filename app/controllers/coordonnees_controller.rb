class CoordonneesController < ApplicationController
  before_action :set_coordonnee, only: [:show, :edit, :update, :destroy]

  # GET /coordonnees
  # GET /coordonnees.json
  def index
    @coordonnees = Coordonnee.paginate(page: params[:page], :per_page => 30)
  end

  # GET /coordonnees/1
  # GET /coordonnees/1.json
  def show
    @coordonnee = Coordonnee.find(params[:id])
  end

  # GET /coordonnees/new
  def new
    @coordonnee = Coordonnee.new
  end

  # GET /coordonnees/1/edit
  def edit
  end

  # POST /coordonnees
  # POST /coordonnees.json
  def create
    @coordonnee = Coordonnee.new(coordonnee_params)

    respond_to do |format|
      if @coordonnee.save
        format.html { redirect_to @coordonnee, notice: 'Coordonnee was successfully created.' }
        format.json { render :show, status: :created, location: @coordonnee }
      else
        format.html { render :new }
        format.json { render json: @coordonnee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /coordonnees/1
  # PATCH/PUT /coordonnees/1.json
  def update
    respond_to do |format|
      if @coordonnee.update(coordonnee_params)
        format.html { redirect_to @coordonnee, notice: 'Coordonnee was successfully updated.' }
        format.json { render :show, status: :ok, location: @coordonnee }
      else
        format.html { render :edit }
        format.json { render json: @coordonnee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /coordonnees/1
  # DELETE /coordonnees/1.json
  def destroy
    @coordonnee.destroy
    respond_to do |format|
      format.html { redirect_to coordonnees_url, notice: 'Coordonnee was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coordonnee
      @coordonnee = Coordonnee.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def coordonnee_params
      params.require(:coordonnee).permit(:titre, :description, :latitude, :longitude, :airport_id)
    end
end
