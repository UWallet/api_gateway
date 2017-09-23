class GatewayController < ApplicationController
  #Call back to requiere login
  before_action :authenticate_request!, only:[:foo, :registerCard, :updateCard, :deleteCard, :CardsByUser]

  def renderError(message, code, description)
    render status: code,json: {
      message: message,
      code: code,
      description: description
    }
  end
#Function to register user
    def register
            options = {
              :body => params.to_json,
              :headers => {
              'Content-Type' => 'application/json'
              }
            }
            results = HTTParty.post("http://192.168.99.103:3001/users", options)
            if results.code == 201
              head 201
            else
              render json: results.parsed_response, status: results.code
            end
    end

#function to login users
    def login
      options = {
        :body => params.to_json,
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.post("http://192.168.99.103:3001/users/login", options)
      render json: results.parsed_response, status: results.code
    end

#Function to update user password
    def updateUser
      options = {
        :body => params.to_json,
        :headers => {
        'Content-Type' => 'application/json',
        'Authorization' => request.headers['Authorization']
        }
      }
      results = HTTParty.put("http://192.168.99.103:3001/users/"+params[:id], options)
      render json: results.parsed_response, status: results.code
    end
    #To register a new credit card in the database

    def registerCard
        parameters={user_id: (@current_user["id"]).to_i, number: (params[:number]).to_i, amount: (params[:amount]).to_i, expiration_month: (params[:expiration_month]).to_i, expiration_year: (params[:expiration_year]).to_i}
        puts (parameters)
        options = {
          :body => parameters.to_json,
          :headers => {
          'Content-Type' => 'application/json'
          }
        }
        results = HTTParty.post("http://192.168.99.103:3003/credit_cards", options)
        if results.code == 201
          head 201
        else
          render json: results.parsed_response, status: results.code
        end
    end
    def updateCard
        if !(Integer(params[:id]) rescue false)
          renderError("Not Acceptable (Invalid Params)", 406, "The parameter id is not an integer")
          return -1
        end
        resultsGet = HTTParty.get("http://192.168.99.103:3003/credit_card?id="+params[:id])
        userA = (resultsGet["user_id"])
        puts(userA)
        puts( @current_user["id"])
        if userA != (@current_user["id"])
          renderError("Forbidden",403,"current user has no access")
          return -1
        else
          options = {
            :body => params.to_json,
            :headers => {
            'Content-Type' => 'application/json'
            }
          }
          results = HTTParty.put("http://192.168.99.103:3003/credit_cards?id="+params[:id], options)
          if results.code == 201
            head 201
          else
            render json: results.parsed_response, status: results.code
          end
        end
    end
    def deleteCard
        if !(Integer(params[:id]) rescue false)
          renderError("Not Acceptable (Invalid Params)", 406, "The parameter id is not an integer")
          return -1
        end
        resultsGet = HTTParty.get("http://192.168.99.103:3003/credit_card?id="+params[:id])
        userA = (resultsGet["user_id"])
        puts(userA)
        puts( @current_user["id"])
        if userA != (@current_user["id"])
          renderError("Forbidden",403,"current user has no access")
          return -1
        else
          results = HTTParty.delete("http://192.168.99.103:3003/credit_cards?id="+params[:id])
          if results.code == 200
            head 200
          else
            render json: results.parsed_response, status: results.code
          end
        end
    end
    def CardsByUser
        results = HTTParty.get("http://192.168.99.103:3003/credit_cards/user?q="+ @current_user["id"].to_s)    
        render json: results.parsed_response, status: results.code
    end



#example funtion to show how to handle logged user
    def foo
      puts @current_user
    end
end
