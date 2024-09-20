FactoryBot.define do
  factory :result do
    user { User.first || create(:user) }
    challenge { Challenge.first || create(:challenge) }
    regular_points { rand(-500..2000) }
    bonus_points { rand(-500..2000) }
  end
end
