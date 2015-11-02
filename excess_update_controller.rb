class Admin::ExcessUpdateController < Admin::ApplicationController

  skip_before_filter :setup_parameters
  before_filter :generate_report
  before_filter :create_attachment, :except => [:show]
  before_filter :set_excess_updater, :except => [:show]

  def show
    @paginate = true
    @output[:rows] = @output[:rows].paginate(:page => page, :per_page => per_page)

    setup_table
  end

  def exam_history
    channel = pusher_channel('excess_update_exam_history', SecureRandom.hex)

    @excess_updater.create({
      :pusher_channel => channel,
      :user_exam_ids  => @output[:rows].select_ids('user_exams.id'),
      :attachment     => @attachment,
      :strategy       => params[:strategy],
      :mean           => params[:mean],
      :std_dev        => params[:std_dev]
    })

    render :json => { :pusher_channel => channel }
  end

private

  def generate_report
    setup_report # => @report
    @output = @report.run(params, :paginate => false)
  end

  def setup_table
    renderer = @report.renderer_for(:html)
    @table   = renderer.render(@report, @output, setup_columns(@report))
  end

  def create_attachment
    return unless params[:file]

    @attachment = @current_account.attachments.create(:file => params[:file])

    if @attachment.file.nil?
      flash[:error] = t('admin.excess_update.errors.upload_failed')
      redirect_to(:action => :new)
    end
  end

  def set_excess_updater
    report_id = Reports::Report.get_report(params[:action]).new(@current_account, @current_site, @current_user).to_id
    @excess_updater = ExcessUpdate::Base.get_updater(report_id)
  rescue IndexError
    flash[:error] = t('admin.excess_update.errors.report_id_not_found', :report_id => report_id)
    render :action => :show
  end

end
