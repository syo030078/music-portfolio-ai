# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_user!
end
