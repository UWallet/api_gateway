class GatewayController < ApplicationController
  #Call back to requiere login
  before_action :authenticate_request!, only:[:foo, :createTransaction]

  def error(message,code,description)
    render status: code, json:{
      message:message,
      code:code,
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
            results = HTTParty.post("http://192.168.99.101:3001/users", options)
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
      results = HTTParty.post("http://192.168.99.101:3001/users/login", options)
      render json: results.parsed_response, status: results.code
    end

#example funtion to show how to handle logged user
    def foo
      puts @current_user
    end

    def createTransaction
      results1 = checkUser(params[:userid]) #userid user to give the money
      money = checkMoneyUser(@current_user["id"]) # check if the user id that sends the money have the amount
      moneyusergiving = money.parsed_response
      if (moneyusergiving["money"]).to_f > 0 && (moneyusergiving["money"]).to_f >= (params[:amount]).to_f
        if results1.code == 200
          parameters={useridgiving: (@current_user["id"]).to_i, useridreceiving: (params[:userid]).to_i, amount: (params[:amount]).to_f, state: "initial"}
          options = {
            :body => parameters.to_json,
            :headers => {
              'Content-Type' => 'application/json'
            }
          }
          results2 = HTTParty.post("http://192.168.99.101:3000/transactions", options) # create initial state
          transact = results2.parsed_response # transact object to get the id
          if results2.code == 201
            parameters={money: (moneyusergiving["money"]).to_f - (params[:amount]).to_f}
            options = {
              :body => parameters.to_json,
              :headers => {
                'Content-Type' => 'application/json'
              }
            }
            results3 = HTTParty.put("http://192.168.99.101:3001/users/update_money?id=" + (@current_user["id"]).to_s , options) #subtract money from useridgiving
            if results3.code == 204
              parameters={state: "pending"}
              options = {
                :body => parameters.to_json,
                :headers => {
                  'Content-Type' => 'application/json'
                }
              }
              results4 = HTTParty.put("http://192.168.99.101:3000/transactions/" + (transact["id"]).to_s , options) # put pending state
              if results4.code == 204
                money = checkMoneyUser(@current_user["id"]) # check if the user id that sends the money have the amount
                moneyuserreceiving= money.parsed_response
                parameters={money: (moneyuserreceiving["money"]).to_f + (params[:amount]).to_f}
                options = {
                  :body => parameters.to_json,
                  :headers => {
                    'Content-Type' => 'application/json'
                  }
                }
                results5 = HTTParty.put("http://192.168.99.101:3001/users/update_money?id=" + (params[:userid]).to_s , options) #add money from useridreceiving
                if results5.code == 204
                  parameters={state: "complete"}
                  options = {
                    :body => parameters.to_json,
                    :headers => {
                      'Content-Type' => 'application/json'
                    }
                  }
                  results6 = HTTParty.put("http://192.168.99.101:3000/transactions/" + (transact["id"]).to_s , options) # put complete state
                  if results6.code == 204
                    head 201
                  else
                    render json: results6.parsed_response, status: results6.code
                  end
                else
                  render json: results5.parsed_response, status: results5.code
                end
              else
                render json: results4.parsed_response, status: results4.code
              end
            else
              render json: results3.parsed_response, status: results3.code
            end
          else
            render json: results2.parsed_response, status: results2.code
          end
        elsif results1.code == 404
          error("Not Found", 404, "The resource does not exist")
        end
      else
        error("Bad Request", 400, "The user do not have enough money")
        return -1
      end
    end

    def checkUser(id)
      results = HTTParty.get("http://192.168.99.101:3001/users/search_user?id=" + id.to_s)
      return results
    end

    def checkMoneyUser(id)
      results = HTTParty.get("http://192.168.99.101:3001/users/get_money?id=" + id.to_s)
      return results
    end
end
