require 'rails_helper'

RSpec.describe GameQuestion, type: :model do

  let(:game_question) { FactoryGirl.create(:game_question, a:2, b:1, c:4, d:3) }


  context 'game status' do
    it 'correct .variants' do

      game_question.a = 2
      game_question.b = 1
      game_question.c = 4
      game_question.d = 3

      expect(game_question.variants).to eq({
                                            'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3
                                          })
    end

    it 'correct .answer_correct?' do

      game_question.a = 2
      game_question.b = 1
      game_question.c = 4
      game_question.d = 3

      expect(game_question.answer_correct?('b')).to be_truthy
    end


    it 'correct .level & .text delegates' do
      expect(game_question.level).to eq(game_question.question.level)
      expect(game_question.text).to eq(game_question.question.text)
    end

    it 'correct .correct_answer_key' do

      game_question.a = 2
      game_question.b = 1
      game_question.c = 4
      game_question.d = 3

      expect(game_question.correct_answer_key).to eq('b')
    end

  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  context 'user helpers' do
    it 'correct .help_hash' do
      # на фабрике у нас изначально хэш пустой
      expect(game_question.help_hash).to eq({})

      # добавляем пару ключей
      game_question.help_hash[:some_key1] = 'blabla1'
      game_question.help_hash['some_key2'] = 'blabla2'

      # сохраняем модель и ожидаем сохранения хорошего
      expect(game_question.save).to be_truthy

      # загрузим этот же вопрос из базы для чистоты эксперимента
      gq = GameQuestion.find(game_question.id)

      # проверяем новые значение хэша
      expect(gq.help_hash).to eq({some_key1: 'blabla1', 'some_key2' => 'blabla2'})
    end


    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)
      expect(game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')

    end

    it 'correct fifty_fifty' do

      game_question.a = 2
      game_question.b = 1
      game_question.c = 4
      game_question.d = 3

      expect(game_question.help_hash).not_to include(:fifty_fifty)

      game_question.add_fifty_fifty

      expect(game_question.help_hash).to include(:fifty_fifty)
      ff = game_question.help_hash[:fifty_fifty]

      expect(ff).to include('b')
      expect(ff.size).to eq 2

    end

    it 'correct friend call' do
      expect(game_question.help_hash).not_to include(:friend_call)

      game_question.add_friend_call

      expect(game_question.help_hash).to include(:friend_call)
      expect(game_question.help_hash[:friend_call]).to be
    end

  end
end
