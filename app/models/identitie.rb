class Identitie < ActiveRecord::Base
    belongs_to :user
    validates_presence_of :provider, :uid, :user_id

    def self.find_with_omniauth(auth)
      find_by(provider: auth["provider"], uid: auth["uid"])
    end
    
    def self.create_with_omniauth(user, auth)
        user.identities.build do |identitie|
            identitie.user = user
            identitie.provider = auth["provider"]
            identitie.uid = auth["uid"]
            identitie.save
        end
    end
end
