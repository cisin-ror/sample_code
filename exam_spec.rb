require 'spec_helper'

describe Exam do
  describe 'time_remaining_notifications' do
    it 'should not include negative values' do
      exam = Exam.new(:time_remaining_notifications => '-2,2')
      expect(exam.time_remaining_notifications).to eq([2])
    end

    it 'should remove duplicates' do
      exam = Exam.new(:time_remaining_notifications => '2,2')
      expect(exam.time_remaining_notifications).to eq([2])
    end
  end

  describe '.clone' do
    let(:exam)        { Factory.create(:exam_with_questions_and_exam_breaks).reload }
    let(:cloned_exam) { exam.clone }

    before { cloned_exam.save! }

    it 'clones exam' do
      expect(cloned_exam.created_by_id).to eq(exam.created_by_id)
    end

    it 'clones the related exam forms' do
      expect(cloned_exam.forms.map(&:name)).to eq(exam.forms.map(&:name))
    end
  end
end

