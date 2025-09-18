module Api
  module V1
    class UsersController < ApplicationController
      def show
        render json: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name
        }
      end

      def update
        if current_user.update(user_params)
          render json: current_user
        else
          render json: { errors: current_user.errors }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name)
      end
    end
  end
end
