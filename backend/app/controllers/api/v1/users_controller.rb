module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate_user!, only: [:profile]

      def show
        render json: user_payload(current_user)
      end

      def profile
        user = User.active.find_by(uuid: params[:uuid])

        if user.nil?
          render_error("ユーザーが見つかりません", :not_found)
          return
        end

        render json: public_user_payload(user)
      end

      def update
        if current_user.update(user_params)
          render json: user_payload(current_user)
        else
          render_validation_errors(current_user)
        end
      end

      private

      def user_params
        params.require(:user).permit(:name)
      end

      # 本人向け（email を含む）
      def user_payload(user)
        {
          uuid: user.uuid,
          email: user.email,
          name: user.name,
          is_musician: user.is_musician,
          is_client: user.is_client
        }
      end

      # 他ユーザーにも公開するプロフィール（email を含めない）
      def public_user_payload(user)
        {
          uuid: user.uuid,
          name: user.name,
          bio: user.bio,
          is_musician: user.is_musician,
          is_client: user.is_client
        }
      end
    end
  end
end
