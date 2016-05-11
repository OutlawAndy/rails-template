class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :json_request?
  protect_from_forgery with: :exception

  def index
  end

  protected

  def json_request?
    request.format.json?
  end

end
