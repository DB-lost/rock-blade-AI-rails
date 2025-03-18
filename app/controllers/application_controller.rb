class ApplicationController < ActionController::Base
  include Authentication
  include BreadcrumbHelper
  include ErrorHandling

  helper_method :breadcrumbs, :add_breadcrumb
  # 对移动端采用宽松要求，桌面端保持现代特性要求
  allow_browser versions: {
    # 移动端浏览器
    ios: 12,          # iOS Safari 12+
    android: 81,      # Android Chrome 81+
    samsung: 12,      # Samsung Internet 12+

    # 桌面端浏览器
    chrome: :modern,
    firefox: :modern,
    safari: :modern
  }

  private

  def set_default_breadcrumb
    add_breadcrumb "Home", root_path
  end

  def current_user
    Current.session&.user
  end

  helper_method :current_user
end
