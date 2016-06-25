FactoryGirl.define do
  factory :game_question do

    association :question
    association :game

    after(:build) { |q|
      ans = [1,2,3,4]
      q.a = ans.shuffle!.pop
      q.b = ans.shuffle!.pop
      q.c = ans.shuffle!.pop
      q.d = ans.shuffle!.pop
    }

  end
end