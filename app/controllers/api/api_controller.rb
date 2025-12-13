module Api
  class ApiController < ApplicationController
    include Miscellany::HttpErrorHandling
    include Miscellany::SlicedResponse

    def not_found
      render json: { error: "Not Found" }, status: :not_found
    end
  end
end
