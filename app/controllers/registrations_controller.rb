class RegistrationsController < ApplicationController
  include RegistrationSteps

  allow_unauthenticated_access only: [ :new, :create, :send_verification_code, :change_step ]

  def new
    @user = User.new
    @user.phone = get_registration_data(:phone) if @current_step > 0
  end

  def create
    @user = User.new(user_params)

    case @current_step
    when 0
      if SmsService.verify_code(params[:user][:phone], params[:user][:verification_code])
        store_registration_data!(:phone, params[:user][:phone])
        next_step!
        redirect_to new_registration_path, notice: "Phone verification successful"
      else
        raise StandardError.new("Invalid verification code")
      end
    when 1
      @user.phone = get_registration_data(:phone)
      if @user.save
        reset_registration!
        start_new_session_for @user
        redirect_to root_path, notice: "Account create successful, welcome!"
      else
        raise StandardError.new(@user.errors.full_messages.join(", "))
      end
    when 2
      reset_registration!
    end
  rescue StandardError => e
    handle_error(e)
  end

  def send_verification_code
    if SmsService.send_code(params[:phone])
      render json: { status: "success" }
    else
      raise StandardError.new("Failed to send verification code")
    end
  rescue StandardError => e
    handle_error(e)
  end

  def change_step
    requested_step = params[:step].to_i

    if requested_step == 0
      reset_registration!
      redirect_to new_registration_path, notice: "Back to phone verification"
    elsif requested_step > @current_step + 1
      redirect_to new_registration_path, alert: "Please complete the current step first"
    elsif requested_step <= @current_step
      session[:registration_step] = requested_step
      redirect_to new_registration_path
    else
      redirect_to new_registration_path
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :username,
      :email_address,
      :password,
      :password_confirmation,
      :phone,
      :verification_code
    )
  end
end
