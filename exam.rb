class Exam < ActiveRecord::Base
  include SoftDelete
  include Searchable

  ALWAYS_SHOW = 'always'
  NEVER_SHOW = 'never'
  SHOW_ONCE = 'once'

  belongs_to :owner
  belongs_to :site

  has_many :breaks
  accepts_nested_attributes_for :breaks


  has_many :allowed_exams, :as => :allowable
  has_many :user_exams
  has_many :exam_forms, :dependent => :destroy

  validates_presence_of :created_by
  validates_presence_of :site
  validates_presence_of :time_limit_in_minutes, :if => :has_break?
  validates_numericality_of :time_limit_in_minutes, :only_integer => true, :if => :time_limit_present?

  validate :either_zeros_or_not

  before_validation :set_default_deadline
  after_create :default_score_card
  after_validation :check_review_template

  named_scope :created_by, lambda { |user| { :conditions => { :created_by_id => user.id } } }
  named_scope :name_like, lambda{|name| {:include => :translations,
    :conditions => ["exam_translations.name LIKE ? AND exam_translations.locale = ?", "%#{name}%", locale]}}

  def self.distinct
    selects('DISTINCT exams.*')
  end

  def full_name
    name
  end

  delegate :account, :account_id, :to => :site, :allow_nil => true
  delegate :present?, :to => :time_limit_in_minutes, :prefix => :time_limit

  def restart_numbering_per_part?
    show_as_you_go?
  end

  def have_questions?
    forms.have_questions?
  end

  def show_question_review?(user_exam)
    case show_item_review
      when Exam::ALWAYS_SHOW then true
      when Exam::NEVER_SHOW then false
      when Exam::SHOW_ONCE then
        user_exam.reviewed_at.blank? or
          (Time.now.utc <= user_exam.reviewed_at.utc + 30.minutes)
    end
  end

protected

  def set_in_review
    self.in_review = true
  end

  def either_zeros_or_not
    if breaks.any_use_exam_time_limit?
      unless breaks.all_use_exam_time_limit?
        errors.add(:breaks, t(:breaks_messsage))
      end
    end
  end

  def set_default_deadline
    self.deadline_in_days ||= 0
  end
end
