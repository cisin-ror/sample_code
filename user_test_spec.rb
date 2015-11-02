require 'spec_helper'

describe UserTest do
  describe '.score_to_be_det?' do
    set(:site) { Factory(:site) }
    set(:user) { Factory(:user, :site => site) }
    set(:test) { Factory(:test, :site => site) }

    set(:form)       { Factory(:form_with_questions, :test => test) }
    set(:grant)      { Factory(:test_grant, :user => user, :test => test, :form => form) }
    set(:user_test)  { UserTest.create_from_grant(grant) }


    describe 'with question_answer and scored' do
      before(:each) do
        user_test.user_test_questions.each { |ueq| ueq.capture.save! }
        user_test.reload
      end

      after(:all) do
        user_test.reload
      end

      it 'should have scored question_question_answers' do
        expect(user_test.question_question_answers.count).to eq(3)
        user_test.question_question_answers.each do |question_answer|
          expect(question_answer.score).to_not be_nil
        end
      end
    end

    describe 'with question_answer and unscored' do
      before(:each) do
        Question.update_all(:auto_grading => false)
        user_test.user_test_questions.each { |ueq| ueq.save! }
        user_test.reload
      end

      it 'should have unscored question_question_answers' do
        expect(user_test.question_question_answers.count).to eq(3)
        user_test.question_question_answers.each do |question_answer|
          expect(question_answer.score).to be_nil
        end
      end
    end

    describe 'with question_answer absent' do
      it 'should be false' do
        expect(user_test.question_question_answers.count).to eq(0)
        expect(user_test.score_to_be_det?).to be_falsey
      end
    end
  end
end
