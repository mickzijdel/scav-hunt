class ApplicationController < ActionController::Base
  rescue_from CanCan::AccessDenied do |exception|
    # FIXME: Render proper access denied page. See Black Lightning
    redirect_to root_path, alert: "I'm sorry, I can't let you do that"
  end
end
