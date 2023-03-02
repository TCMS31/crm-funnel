# frozen_string_literal: true

# Liveness/readiness probe used by the container healthcheck. It touches the
# database, so a container that cannot reach Postgres reports unhealthy instead
# of accepting traffic it cannot serve.
class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: { status: 'ok', database: 'ok' }
  rescue ActiveRecord::ActiveRecordError => e
    render json: { status: 'error', database: e.class.name }, status: :service_unavailable
  end
end
