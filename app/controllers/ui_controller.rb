class UiController < ApplicationController
  def index
    render component: "App", prerender: false, layout: "application"
  end
end
