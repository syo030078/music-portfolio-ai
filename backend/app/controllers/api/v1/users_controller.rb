module Api
  module V1
    class UsersController < ApplicationController
      def show
        render json: {
          uuid: current_user.uuid,
          email: current_user.email,
          name: current_user.name,
          is_musician: current_user.is_musician,
          is_client: current_user.is_client
        }
      end

      def update
        if current_user.update(user_params)
          render json: {
            uuid: current_user.uuid,
            email: current_user.email,
            name: current_user.name,
            is_musician: current_user.is_musician,
            is_client: current_user.is_client
          }
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
