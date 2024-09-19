FactoryBot.define do
  sequence :challenge_number do |n|
    n + 1000
  end

  factory :challenge do
    number { generate(:challenge_number) }
    points { rand(500..2000) }
    description { "This is challenge #{number}" }
  end
end
