module Api::V1
  class ExtDataController < Api::ApiController
    def lookup_upc_code
      response = Net::HTTP.get(URI("https://api.upcitemdb.com/prod/trial/lookup?upc=#{params[:upc]}"))
      render json: response
    end
  end
end
