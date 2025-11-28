FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    sequence(:name) { |n| "Test User #{n}" }
    bio { "Test bio" }

    after(:create) do |user|
      user.reload
    end
  end
end
