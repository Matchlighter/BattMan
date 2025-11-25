class BatteriesController < ApplicationController
  def index
    @batteries = Battery.all.order(:id)
  end

  def show
    @battery = Battery.find(params[:id])
  end
end
