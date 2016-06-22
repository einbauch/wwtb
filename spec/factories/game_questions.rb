FactoryGirl.define do
  factory :game_question do
    a 4
    b 3
    c 2
    d 1

    association :question
    association :game

  end
end