class BatteriesController < ApplicationController
  def index
    @batteries = Battery.all
  end
end
