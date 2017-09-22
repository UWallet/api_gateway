class GatewayController < ApplicationController

 before_action :authenticate_request!, only:[:foo]

    def register
            options = {
              :body => params,
              :headers => {
              'Content-Type' => 'application/json'
              }
            }
            results = HTTParty.post("http://192.168.99.101:3001/users", options)
            if results.code == 201
              head 201
            else
              render json: results.parsed_response, status: results.code
            end
    end

    def login
      options = {
        :body => params,
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.post("http://192.168.99.101:3001/user/login", options)
      render json: results.parsed_response, status: results.code
    end

    def foo
      puts @current_user
    end
end
