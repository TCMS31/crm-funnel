# frozen_string_literal: true

# Exception handler class to handle exceptions
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |_e|
      render 'shared/not_found', status: :not_found
    end
  end
end
