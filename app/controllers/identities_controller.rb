class IdentitiesController < ApplicationController
  before_action :search
  before_action :signed_in_user

  def new
    @identitie = Identitie.new
  end

  def index
    @identities = Identitie.all
  end

  def omniauth
    # recupération donnée en provenance du reseau social dans la variable auth
    # Pour visualiser le contenu de la variable auth ecrire : render :text => auth.inspect
    auth = request.env["omniauth.auth"]
    # Connexion au reseau social uniquement si l'utilisateur est enregistre
    if signed_in?
      # verifie si un identifiant social est présent pour cet utilisateur
      identitie = Identitie.find_with_omniauth(auth)
      # Si oui : Affichage d'un message sur l'ecran
      #    non : Creation d'un identifiant social
      if identitie.nil?
        identitie = Identitie.create_with_omniauth(current_user, auth)
        # Si la creation de l'identifiant s'est bien passé sauvegarde dans la session
        # de l'utilisateur courant
        # Dans le cas contraire affichage d'une anomalie sur l"ecran
        if identitie
          user = identitie.user
          session[:user_id] = user
          redirect_to identities_url, notice: "Account successfully authenticated"
        else
          redirect_to identities_url, notice: "PB Account unsuccessfully authenticated"
        end
      else
        redirect_to identities_url, notice: "You have already linked this account #{identitie}"
      end
    end
  end

  def destroy
    @identitie = Identitie.find(params[:id])
    @identitie.destroy
    redirect_to identities_url
  end

  private

  def identitie_params
    params.require(:identitie).permit(:provider, :uid, :user_id)
  end
end
