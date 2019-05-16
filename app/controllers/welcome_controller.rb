class WelcomeController < ApplicationController
  before_action :search
  def home
    if signed_in?
      @micropost  = current_user.microposts.build
      @feed_items = current_user.feed.paginate(page: params[:page], :per_page => 30)
    end
  end
  
  def listevol
  end

  def policy
  end

  def about
  end

  def team
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def search_params
        params.require(:search).permit!
    end
end
