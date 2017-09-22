class GatewayController < ApplicationController
  #Call back to requiere login
  before_action :authenticate_request!, only:[:foo]

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

#example funtion to show how to handle logged user
    def foo
      puts @current_user
    end
end
