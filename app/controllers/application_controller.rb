class ApplicationController < ActionController::API




  protected
# Validates the token and user and sets the @current_user scope
  def authenticate_request!
    options = {
      :headers => {
      'Authorization' => request.headers['Authorization']
      }
    }
    results = HTTParty.get("http://192.168.99.102:3001/users/get_user", options)
    if results.code == 200
        @current_user=results.parsed_response
    else
      render json: results.parsed_response, status: results.code
    end
  end
end
