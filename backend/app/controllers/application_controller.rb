# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ErrorRenderable

  before_action :authenticate_user!
end
