module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :authenticate_user!, if: -> { respond_to?(:authenticate_user!) }

      def show
        db_status = begin
          ActiveRecord::Base.connection.execute("SELECT 1")
          "connected"
        rescue StandardError
          "disconnected"
        end

        status = db_status == "connected" ? :ok : :service_unavailable

        render json: {
          status: status == :ok ? "ok" : "degraded",
          database: db_status,
          timestamp: Time.current.iso8601
        }, status: status
      end
    end
  end
end
