namespace :db do
  	desc "Fill database with sample data"
  	task populate: :environment do
    	make_users
    	make_microposts
    	make_relationships
  	end
end

def make_users
    User.delete_all  # suppression de la table utilisateur
    User.reset_pk_sequence # remise de l'id à 1 pour table utilisateur
  	admin = User.create!(name:     "Pinfada andre",
    	                   email:    "pinfada.andre@gmail.com",
        	               password: "testpwd",
            	           password_confirmation: "testpwd",
                	       admin: true)
  	9.times do |n|
    	name  = Faker::Name.name
    	email = "example-#{n+1}@test.com"
    	password  = "testpwdbis"
    	User.create!(name:     name,
        	         email:    email,
            	     password: password,
                	 password_confirmation: password)
  	end
end

def make_microposts
    Micropost.delete_all  # suppression de la table micropost
    Micropost.reset_pk_sequence # remise de l'id à 1 pour table micropost
  	users = User.limit(6)
  	10.times do
    	content = Faker::Lorem.sentence(5)
    	users.each { |user| user.microposts.create!(content: content) }
  	end
end

def make_relationships
    Relationship.delete_all  # suppression de la table micropost
    Relationship.reset_pk_sequence # remise de l'id à 1 pour table micropost
    users = User.all
    user  = users.first
    followed_users = users[2..50]
    followers      = users[3..40]
    followed_users.each { |followed| user.follow!(followed) }
    followers.each      { |follower| follower.follow!(user) }
end