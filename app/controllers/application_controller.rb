class ApplicationController < ActionController::API

  def renderResponse(message, code, description)
    render status: code,json: {
      message: message,
      code: code,
      description: description
    }
  end


  protected
# Validates the token and user and sets the @current_user scope
  def authenticate_request!
    if request.headers['Authorization']
      options = {
        :headers => {
        'Authorization' => request.headers['Authorization']
        }
      }
      results = HTTParty.get("http://192.168.99.101:3001/users/get_user", options)
      if results.code == 200
          @current_user=results.parsed_response
      else
        render json: results.parsed_response, status: results.code
      end
    else
      renderResponse("Bad Request", 400, "token not in request")
    end
  end
end
