FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "タイトル#{n}" }
    sequence(:content) { |n| "本文#{n}" }
    association :user
  end
end
