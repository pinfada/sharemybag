FactoryBot.define do
  factory :identity, class: 'Identitie' do
    provider "MyString"
    uid "MyString"
    user nil
  end
end
