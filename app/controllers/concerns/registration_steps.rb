module RegistrationSteps
  extend ActiveSupport::Concern

  included do
    before_action :set_registration_step
  end

  private

  def set_registration_step
    @current_step = session[:registration_step].to_i
  end

  def next_step!
    session[:registration_step] = @current_step + 1
  end

  def store_registration_data!(key, value)
    session["registration_#{key}"] = value
  end

  def get_registration_data(key)
    session["registration_#{key}"]
  end

  def reset_registration!
    session.delete(:registration_step)
    session.keys.select { |k| k.to_s.start_with?("registration_") }.each do |key|
      session.delete(key)
    end
  end
end
