class ApplicationController < ActionController::Base
  include PaginationDefaults
  include Authentication

  protect_from_forgery

  attr_reader :current_account, :current_user

  before_filter :clear_cache
  before_filter :setup_default
  before_filter :reset_current_user

  helper_method :locked?
  helper_method :invigilator?
  helper_method :admin?

  filter_parameter_logging :password, :credit_card, :token

protected

  def admin?
    false
  end

  # prefix uri with asset_host
  def asset_uri(request, source)
    host = ActionController::Base.asset_host
    if host.is_a?(Proc) || host.respond_to?(:call)
      case host.is_a?(Proc) ? host.arity : host.method(:call).arity
      when 2
        host = host.call(source, request)
      else
        host = host.call(source)
      end
    else
      host = (host =~ /%d/) ? host % (source.hash % 4) : host
    end

    "#{host}#{source}"
  end

  def locked?
    request.headers['HTTP_X_LOCKED'].present?
  end

  def invigilator?
    session[:invigilator].present?
  end

protected

  def reset_current_user
    ActiveRecord::Base.set_current_user(nil)
  end

  # :user => 'student' (user, candidate, etc.)
  def load_i18n_labels(set = '')
    I18n.set_label_set!(set)
  end

  def apply_measure_header_wedge!(html)
    head_html = render_to_string(:partial => 'measure/header')
    html.sub!(/<head>/, head_html.sub('</head>', ''))
  end

  def redirect_back_or_else(options = {})
    redirect_to(request.referer) and return if request.referer
    block_given? ? yield : redirect_to(options)
  end

  def email_extras(model, tag)
    {
      :owner_type => model.class.name,
      :owner_id => model.id,
      :tag => "#{@current_site.short_name}_#{tag}"
    }
  end

private

  def record_invalid_to_errors(error)
    ErrorFormatting.record_invalid_to_errors(error)
  end

  def clear_cache
    ReqCache.clear
  end

  def setup_default
    Resource.request({
      :request_id => request.env['HTTP_X_REQUEST_ID'],
      :user_agent => user_agent
    })
  end

  def notice_error(error)
    Error.notice(error, :request => request)
  end
end
