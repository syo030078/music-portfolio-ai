FactoryBot.define do
  factory :job do
    association :client, factory: :user
    sequence(:title) { |n| "Test Job #{n}" }
    description { "Test job description" }
    budget_jpy { 100000 }
    budget_min_jpy { 50000 }
    budget_max_jpy { 150000 }
    delivery_due_on { 30.days.from_now.to_date }
    is_remote { true }
    location_note { "Tokyo" }
    status { 'draft' }

    after(:create) do |job|
      job.reload
    end

    trait :published do
      status { 'published' }
      published_at { 1.day.ago }
    end

    trait :contracted do
      status { 'contracted' }
      published_at { 7.days.ago }
    end
  end
end
