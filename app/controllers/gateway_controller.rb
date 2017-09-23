class GatewayController < ApplicationController
  #Call back to requiere login
  before_action :authenticate_request!, only:[:foo,:CreateItemOfList,:updatePendingPay,:deletePendingPay, :showListPendingPays ]

  def renderError(message, code, description)
  render status: code,json: {
    message: message,
    code: code,
    description: description
  }
  end

#Function to create a item of list
  def CreateItemOfList
    parameters={user_id: (@current_user["id"]).to_i, description: (params[:description]), date_pay: params[:date_pay], cost: params[:cost], target_account: params[:target_account]}
    #puts (parameters)
    options = {
      :body => parameters.to_json,
      :headers => {
      'Content-Type' => 'application/json'
      }
    }
    results = HTTParty.post("http://192.168.99.102:3005/lists", options)
    if results.code == 201
      head 201
    else
      render json: results.parsed_response, status: results.code
    end
  end

#Function to show a list of pending pays
  def showListPendingPays
    puts @current_user
    results = HTTParty.get("http://192.168.99.102:3005/lists/by_user?user_id="+(@current_user["id"]).to_s)
    if results.code == 200
      render json: results.parsed_response, status: 200
    else
      render json: results.parsed_response, status: results.code
    end
  end

#Function to update a item of list
  def updatePendingPay
    if !(Integer(params[:id]) rescue false)
      renderError("Not Acceptable (Invalid Params)", 406, "The parameter id is not an integer")
      return -1
    end
    options = {
      :body => params.to_json,
      :headers => {
        'Content-Type' => 'application/json'
      }
    }
    resul = HTTParty.get("http://192.168.99.102:3005/lists/"+params[:id])
    user = resul["user_id"]
    if user == (@current_user["id"]).to_i
      results = HTTParty.put("http://192.168.99.102:3005/lists/"+params[:id], options)
      if results.code == 201
        head 201
      else
        render json: results.parsed_response, status: results.code
      end
    else
      renderError("Not Acceptable (Invalid Params)", 403, "The user does not have permmision")
    end
  end

  def deletePendingPay
    if !(Integer(params[:id]) rescue false)
      renderError("Not Acceptable (Invalid Params)", 406, "The parameter id is not an integer")
      return -1
    end

    resul = HTTParty.get("http://192.168.99.102:3005/lists/"+params[:id])
    user = resul["user_id"]
    if user == (@current_user["id"]).to_i
      results = HTTParty.delete("http://192.168.99.102:3005/lists/"+params[:id])
      if results.code == 200
        head 200
      else
        render json: results.parsed_response, status: results.code
      end
    else
      renderError("Not Acceptable (Invalid Params)", 403, "The user does not have permmision")
    end
  end

#Function to register user
    def register
            options = {
              :body => params.to_json,
              :headers => {
              'Content-Type' => 'application/json'
              }
            }
            results = HTTParty.post("http://192.168.99.102:3001/users", options)
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
      results = HTTParty.post("http://192.168.99.102:3001/users/login", options)
      render json: results.parsed_response, status: results.code
    end

#example funtion to show how to handle logged user
    def foo
      puts @current_user
    end
end
