module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_error
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  end

  private

  def handle_validation_error(exception)
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { errors: exception.record.errors }, status: :unprocessable_entity }
      format.turbo_stream { render turbo_stream: turbo_stream.update("error_messages", partial: "shared/error_messages", locals: { errors: exception.record.errors }) }
    end
  end

  def handle_error(error)
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: error.message }
      format.json { render json: { error: error.message }, status: :unprocessable_entity }
      format.turbo_stream { render turbo_stream: turbo_stream.update("error_messages", partial: "shared/error_messages", locals: { message: error.message }) }
    end
  end
end
