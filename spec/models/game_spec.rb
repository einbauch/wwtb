require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryGirl.create(:user)}
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user)}

  context 'Game Factory' do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)

      game = nil

      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and (
        change(GameQuestion, :count).by(15)
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.previous_game_question).to eq q
      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey

    end

    it 'take money! finishes game and writes correct prize money' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end

  end


  context '.status' do

    it 'returns :money if money is taken' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!
      expect(game_w_questions.status).to eq(:money)
    end

    it 'returns :in_progress if answers are correct' do
      Question::QUESTION_LEVELS.each do |i|
        break if i == 14
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)
        expect(game_w_questions.status).to eq(:in_progress)
      end
    end

    it 'returns :won if the game is won' do
      game_w_questions.current_level = 14
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      expect(game_w_questions.status).to eq(:won)
    end

    it 'returns :fail if answer is wrong' do
      q = game_w_questions.current_game_question
      wrong_answers = %w(a b c d)
      wrong_answers.delete(q.correct_answer_key)

      wrong_answers.each do |i|
        game_w_questions.answer_current_question!(i)
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    it 'returns :timeout if time is out' do
      q = game_w_questions.current_game_question
      game_w_questions.created_at = Time.now - 2.hours
      game_w_questions.answer_current_question!(q.correct_answer_key)
      expect(game_w_questions.status).to eq(:timeout)
    end

  end

  context 'game questions' do

    it 'current_game_question should return current level question' do
      Question::QUESTION_LEVELS.each do |i|
        g = game_w_questions
        g.current_level = i
        expect(g.current_game_question).to eq(g.game_questions[i])
      end
    end

    it 'previous_game_question should return previous question or nil if level is 0' do
      Question::QUESTION_LEVELS.each do |i|
        g = game_w_questions
        g.current_level = i
        if i == 0
          expect(g.previous_game_question).to eq(nil)
        else
          expect(g.previous_game_question).to eq(g.game_questions[i-1])
        end
      end
    end

    it 'previous_level should return previous level' do
      Question::QUESTION_LEVELS.each do |i|
        g = game_w_questions
        g.current_level = i
        expect(g.previous_level).to eq(i-1)
      end
    end

  end

  context '.answer_current_question!' do

    it 'answer correct but not last' do
      q = game_w_questions.current_game_question
      level = game_w_questions.current_level
      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_truthy
      expect(game_w_questions.current_level).to eq(level+1)
      expect(game_w_questions.finished_at).to eq(nil)
      expect(game_w_questions.status).to eq(:in_progress)
    end

    it 'answer correct and last' do
      q = game_w_questions.current_game_question
      game_w_questions.current_level = 14
      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_truthy
      expect(game_w_questions.current_level).to eq(15)
      expect(game_w_questions.finished_at).not_to eq(nil)
      expect(game_w_questions.status).to eq(:won)
    end

    it 'time is up' do
      q = game_w_questions.current_game_question
      game_w_questions.created_at = Time.now - 2.hours
      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_falsey
      expect(game_w_questions.finished_at).not_to eq(nil)
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'wrong answer' do
      q = game_w_questions.current_game_question
      wrong_answers = %w(a b c d)
      wrong_answers.delete(q.correct_answer_key)

      wrong_answers.each do |i|
        expect(game_w_questions.answer_current_question!(i)).to be_falsey
        expect(game_w_questions.finished_at).not_to eq(nil)
        expect(game_w_questions.status).to eq(:fail)
      end
    end

  end

end

