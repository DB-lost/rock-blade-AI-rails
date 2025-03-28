class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbHelper
  include ErrorHandling

  helper_method :breadcrumbs, :add_breadcrumb
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def set_default_breadcrumb
    add_breadcrumb "Home", root_path
  end

  def current_user
    Current.session&.user
  end

  helper_method :current_user
end
