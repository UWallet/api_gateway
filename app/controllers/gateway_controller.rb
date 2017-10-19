class GatewayController < ApplicationController
  #Call back to requiere login
  before_action :authenticate_request!, only:[:logout,:updateUser, :verifyPass, :getUser, :registerCard, :updateCard, :deleteCard, :cardsByUser, :transactionByUser, :createTransaction,:createItemOfList,:updatePendingPay,:deletePendingPay, :showListPendingPays, :transferMoneyFromCard, :generateAll, :generateDays]

  def renderError(message, code, description)
  render status: code,json: {
    message: message,
    code: code,
    description: description
  }
  end

  #############################
  #    list_pay_ms
  #############################


#Function to create a item of list
  def createItemOfList
    results1 = checkUser(params[:target_account]) #userid user to give the money
    if results1.code == 200
      parameters={user_id: (@current_user["id"]).to_i, description: (params[:description]), date_pay: params[:date_pay], cost: params[:cost], target_account: params[:target_account], state_pay:params[:target_account]}
      options = {
        :body => parameters.to_json,
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.post("http://192.168.99.101:3005/lists", options)
      if results.code == 201
        head 201
      else
        render json: results.parsed_response, status: results.code
      end
    elsif results1.code == 404
      renderError("Not Found", 404, "The resource does not exist")
    end
  end

#Function to show a list of pending pays
  def showListPendingPays
    puts @current_user
    results = HTTParty.get("http://192.168.99.101:3005/lists/by_user?user_id="+(@current_user["id"]).to_s)
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
    resul = HTTParty.get("http://192.168.99.101:3005/lists/"+params[:id])
    user = resul["user_id"]
    if user == (@current_user["id"]).to_i
      results = HTTParty.put("http://192.168.99.101:3005/lists/"+params[:id], options)
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

    resul = HTTParty.get("http://192.168.99.101:3005/lists/"+params[:id])
    user = resul["user_id"]
    if user == (@current_user["id"]).to_i
      results = HTTParty.delete("http://192.168.99.101:3005/lists/"+params[:id])
      if results.code == 200
        head 200
      else
        render json: results.parsed_response, status: results.code
      end
    else
      renderError("Not Acceptable (Invalid Params)", 403, "The user does not have permmision")
    end
  end

  #############################
  #    auth_ms
  #############################



#function to create group
  def create_group(user_id,device_token)
    @key_name_prefix="test4_"
    options = {
      :body =>{"operation": "create",
              "notification_key_name": @key_name_prefix+user_id.to_s,
              "registration_ids": [device_token]
              }.to_json,
      :headers => {'Content-Type'=> 'application/json',
                    'Authorization' => 'key = AAAAE0hYQbA:APA91bEdyT2IqQcv0xbWqGrbxaU2ty3KOmV2Fj7-w5-7rU3W03C6pU61WUEwyNSXFhRtq2LO68rljjM4YFYQOpWUNOsSZHulxPQVulQsMgMx5zstPEfvGj900Az_NinDBmXvDEoK7NlW  ',
                    'project_id' => '82818122160'
                  }
    }
    return results2 = HTTParty.post("https://android.googleapis.com/gcm/notification",options)
  end

#update gruopkey on db
  def update_key(notification_key, user)
    options = {
      :body =>{ "notification_key": notification_key,
                "user_id": user
      }.to_json,
      :headers => {'Content-Type'=> 'application/json'
                  }
    }
    return result_update = HTTParty.put("http://192.168.99.101:3001/group_keys/update_key", options)
  end

#Function to register user
    def register
      @key_name_prefix="test4_"
            options = {
              :body => params.to_json,
              :headers => {
              'Content-Type' => 'application/json'
              }
            }
            results = HTTParty.post("http://192.168.99.101:3001/users", options)
            if results.code == 201
              user = results.parsed_response
              aux =  params[:user]
              options = {
                :body =>{ "notification_key": "",
                          "user_id": user
                }.to_json,
                :headers => {'Content-Type'=> 'application/json'
                            }
              }
              results3 = HTTParty.post("http://192.168.99.101:3001/group_keys".to_s,options)
              if results3.code == 201
                head 201
              else
                render json: results3.parsed_response, status: results3.code
              end
          else
            render json: results.parsed_response, status: results.code
          end
    end

#function to login users
    def login
      @key_name_prefix="test4_"
      options = {
        :body => params.to_json,
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.post("http://192.168.99.101:3001/users/login", options)
      if results.code == 200
        @aux = results.parsed_response["notification_key"]
        @aux = @aux["notification_key"]
        if @aux == ""
          result = create_group(results.parsed_response["id"].to_s, params[:device_token])
          if result.code != 200
            renderError("Not Acceptable", 400, "No se pudo crear el grupo, razon: "+result.parsed_response["error"])
            return -1
          end
          @aux = result.parsed_response["notification_key"]
          result_update = update_key(@aux, results.parsed_response["id"].to_s)
          if result_update.code != 200
            render json: result_update.parsed_response, status: result_update.code
            return -1
          end
          render json: {auth_token: results.parsed_response["auth_token"]}.to_json, status: results.code
          return
        end
        options = {
          :body =>{"operation": "add",
                   "notification_key_name": @key_name_prefix+results.parsed_response["id"].to_s,
                   "notification_key": @aux,
                   "registration_ids": [params[:device_token]]
                  }.to_json,
          :headers => {'Content-Type'=> 'application/json',
                        'Authorization' => 'key = AAAAE0hYQbA:APA91bEdyT2IqQcv0xbWqGrbxaU2ty3KOmV2Fj7-w5-7rU3W03C6pU61WUEwyNSXFhRtq2LO68rljjM4YFYQOpWUNOsSZHulxPQVulQsMgMx5zstPEfvGj900Az_NinDBmXvDEoK7NlW  ',
                        'project_id' => '82818122160'
                      }
        }
        results2 = HTTParty.post("https://android.googleapis.com/gcm/notification",options)
        if results2.code ==200
          render json: {auth_token: results.parsed_response["auth_token"]}.to_json, status: results.code
          return
        elsif results2.code == 400
          if results2.parsed_response["error"] == "notification_key not found"
            result2 = create_group(results.parsed_response["id"].to_s, params[:device_token])
            if result2.code != 200
              renderError("Not Acceptable", 400, "No se pudo crear el grupo, razon: "+result2.parsed_response["error"])
              return -1
            end
            @aux = result2.parsed_response["notification_key"]
            result_update = update_key(@aux, results.parsed_response["id"].to_s)
            if result_update.code != 200
              render json: result_update.parsed_response, status: result_update.code
              return -1
            end
            render json: {auth_token: results.parsed_response["auth_token"]}.to_json, status: results.code
            return
          end
          render json: results2.parsed_response, status: results2.code
          return
        else
          renderError("Not Acceptable", 400, "No se pudo crear el grupo, razon: "+results2.parsed_response["error"])
          return
        end
    else
      render json: results.parsed_response, status: results.code
    end
  end

#function to logOut

  def logout
    @key_name_prefix="test4_"
    options = {
      :body =>{"operation": "remove",
               "notification_key_name": @key_name_prefix+@current_user["id"].to_s,
               "notification_key": @current_user_notification_key,
               "registration_ids": [params[:device_token]]
              }.to_json,
      :headers => {'Content-Type'=> 'application/json',
                    'Authorization' => 'key = AAAAE0hYQbA:APA91bEdyT2IqQcv0xbWqGrbxaU2ty3KOmV2Fj7-w5-7rU3W03C6pU61WUEwyNSXFhRtq2LO68rljjM4YFYQOpWUNOsSZHulxPQVulQsMgMx5zstPEfvGj900Az_NinDBmXvDEoK7NlW  ',
                    'project_id' => '82818122160'
                  }
    }
    results2 = HTTParty.post("https://android.googleapis.com/gcm/notification",options)
    if results2.code == 200
      puts "me sali"
      head 200
    else
      render json: results2.parsed_response, status: results2.code
    end
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
      results = HTTParty.put("http://192.168.99.101:3001/users/"+@current_user["id"].to_s, options)
      render json: results.parsed_response, status: results.code
    end

    #Function to get user info
    def getUser
      render json: @current_user, status: 200
    end

    #function to verify password
    def verifyPass
      options = {
        :body => params.to_json,
        :headers => {
        'Content-Type' => 'application/json',
        'Authorization' => request.headers['Authorization']
        }
      }
      results = HTTParty.post("http://192.168.99.101:3001/users/verify_pass?id="+ @current_user["id"].to_s, options)
      render json: results.parsed_response, status: results.code
    end


    #############################
    #    credit_cards_ms
    #############################
    #To register a new credit card in the database, need the user to be logged
    def registerCard
        parameters={user_id: (@current_user["id"]).to_i, number: (params[:number]).to_i, amount: (params[:amount]).to_i, expiration_month: (params[:expiration_month]).to_i, expiration_year: (params[:expiration_year]).to_i}
        puts (parameters)
        options = {
          :body => parameters.to_json,
          :headers => {
          'Content-Type' => 'application/json'
          }
        }
        results = HTTParty.post("http://192.168.99.101:3003/credit_cards", options)
        if results.code == 201
          head 201
        else
          render json: results.parsed_response, status: results.code
        end
    end
    #Used by the user to update the expiration info of the card, also can be use for update the amount of the credit card
    def updateCard
        if !(Integer(params[:id]) rescue false)
          renderError("Not Acceptable (Invalid Params)", 406, "The parameter id is not an integer")
          return -1
        end
        resultsGet = HTTParty.get("http://192.168.99.101:3003/credit_card?id="+params[:id])
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
          results = HTTParty.put("http://192.168.99.101:3003/credit_cards?id="+params[:id], options)
          if results.code == 201
            head 201
          else
            render json: results.parsed_response, status: results.code
          end
        end
    end
    #for a current logged user to delete one of it's cards
    def deleteCard
        if !(Integer(params[:id]) rescue false)
          renderError("Not Acceptable (Invalid Params)", 406, "The parameter id is not an integer")
          return -1
        end
        resultsGet = HTTParty.get("http://192.168.99.101:3003/credit_card?id="+params[:id])
        userA = (resultsGet["user_id"])
        puts(userA)
        puts( @current_user["id"])
        if userA != (@current_user["id"])
          renderError("Forbidden",403,"current user has no access")
          return -1
        else
          results = HTTParty.delete("http://192.168.99.101:3003/credit_cards?id="+params[:id])
          if results.code == 200
            head 200
          else
            render json: results.parsed_response, status: results.code
          end
        end
    end
    #Return the cards asociated to a current user
    def cardsByUser
        results = HTTParty.get("http://192.168.99.101:3003/credit_cards/user?id="+ @current_user["id"].to_s)
        render json: results.parsed_response, status: results.code
    end
    #Used to transfer money from a credit card to it's user acount
    def transferMoneyFromCard
      results1 = postTransaction(@current_user["id"], @current_user["id"], params[:money]) # create initial state
      transact = results1.parsed_response # transact object to get the id in the rest of the process
      resultsGet = HTTParty.get("http://192.168.99.101:3003/credit_card?id="+params[:cardId].to_s)
      userA = (resultsGet["user_id"])
      if userA != (@current_user["id"])
        renderError("Forbidden",403,"current user has no access")
        return -1
      else
        if (resultsGet["amount"]<(params[:money]).to_i)
          renderError("Bad Request", 400, "The credit card do not have enough money")
        else
          actualMoney=checkMoneyUser(userA)
          newMoneyUser=(actualMoney["money"]).to_f + (params[:money]).to_i
          newMoneyCard=resultsGet["amount"].to_i - (params[:money]).to_i
          optionsCd = {
            :body => {"amount": newMoneyCard}.to_json,
            :headers => {
            'Content-Type' => 'application/json',
            'Authorization' => request.headers['Authorization']
            }
          }
          resultCd = HTTParty.put("http://192.168.99.101:3003/credit_cards?id="+params[:cardId].to_s, optionsCd)#subtract money from card
          if resultCd.code == 204
            results2 = updateTransaction("pending", transact["id"])# put pending state
          else
            render json: resultCd.parsed_response, status: resultCd.code
          end
          resultUs = updateMoney(newMoneyUser, userA.to_s) #add money to user
          if resultUs.code == 204
            results3 = updateTransaction("complete", transact["id"])# put complete state
            if results3.code == 204
              subject = "Transferencia de tarjeta de credito"
              content = "Has recibido una transferencia de la cuenta " + params[:cardId].to_s + " por valor de $" + (params[:money]).to_s
              createNotification(@current_user["id"],subject, content, @current_user_notification_key)
              head 201 # transaction created and state complete
            else
              render json: results3.parsed_response, status: results3.code
            end
          else
            render json: resultUs.parsed_response, status: resultUs.code
          end
        end
      end
    end


    #############################
    #    transactions_ms
    #############################

#function that gets the transactions sended, received and the loads to the user account
    def transactionByUser
      results = HTTParty.get("http://192.168.99.101:3000/by_user_id?userid=" + (@current_user["id"]).to_s)
      render json: results.parsed_response, status: results.code
    end

#function that gets the transactions sended, received and the loads to the user account
    def transactionById
      results = HTTParty.get("http://192.168.99.101:3000/transactions/" + (params[:id]).to_s)
      render json: results.parsed_response, status: results.code
    end

#function that creates and completes a transaction between users
    def createTransaction
      results1 = checkUser(params[:userid]) #userid user to give the money
      money = checkMoneyUser(@current_user["id"]) # check if the user id that sends the money have the amount
      moneyusergiving = money.parsed_response
      if (moneyusergiving["money"]).to_f > 0 && (moneyusergiving["money"]).to_f >= (params[:amount]).to_f
        if results1.code == 200
          results2 = postTransaction(@current_user["id"], params[:userid], params[:amount]) # create initial state
          transact = results2.parsed_response # transact object to get the id in the rest of the process
          if results2.code == 201
            results3 = updateMoney((moneyusergiving["money"]).to_f - (params[:amount]).to_f, @current_user["id"]) #subtract money from useridgiving
            if results3.code == 204
              results4 = updateTransaction("pending", transact["id"])# put pending state
              if results4.code == 204
                money = checkMoneyUser(params[:userid]) # check if the user id that sends the money have the amount
                moneyuserreceiving= money.parsed_response
                results5 = updateMoney((moneyuserreceiving["money"]).to_f + (params[:amount]).to_f, params[:userid])#add money from useridreceiving
                if results5.code == 204
                  results6 = updateTransaction("complete", transact["id"])# put complete state
                  if results6.code == 204
                    subject = "Transacción"
                    content = "Has recibido una transacción del usuario " + formato(@current_user["id"]) + " por valor de $" + (params[:amount]).to_s
                    puts(content)
                    createNotification(params[:userid],subject, content, @current_user_notification_key)
                    head 201 # transaction created and state complete
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
          renderError("Not Found", 404, "The resource does not exist")
        end
      else
        renderError("Bad Request", 400, "The user do not have enough money")
        return -1
      end
    end

    def formato(id)
      cuenta = id.to_s
      userid=""
      (8-cuenta.length).times do |n|
        userid+='0'
      end
      userid+=cuenta
      return userid
    end

#check if the user exists
    def checkUser(id)
      results = HTTParty.get("http://192.168.99.101:3001/users/search_user?id=" + id.to_s)
      return results
    end

#get money amount of a user
    def checkMoneyUser(id)
      results = HTTParty.get("http://192.168.99.101:3001/users/get_money?id=" + id.to_s)
      return results
    end

#update the money of a user
    def updateMoney(money, id)
      parameters={money: money}
      options = {
        :body => parameters.to_json,
        :headers => {
          'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.put("http://192.168.99.101:3001/users/update_money?id=" + id.to_s , options)
      return results
    end

#update a state transaction "initial" "pending" "complete"
    def updateTransaction(state, id)
      parameters={state: state}
      options = {
        :body => parameters.to_json,
        :headers => {
          'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.put("http://192.168.99.101:3000/transactions/" + id.to_s , options) # put pending state
      return results
    end

#create a transaction state = "initial"
    def postTransaction(useridgiving, useridreceiving, amount)
      parameters={useridgiving: useridgiving.to_i, useridreceiving: useridreceiving.to_i, amount: amount.to_f, state: "initial"}
      options = {
        :body => parameters.to_json,
        :headers => {
          'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.post("http://192.168.99.101:3000/transactions", options) # create initial state
      return results
    end

#############################
#    extracts_ms
#############################
    def generateAll()
      weadejm = HTTParty.get("http://192.168.99.101:3000/by_user_id?userid="+ @current_user["id"].to_s)
      options = {
        :body => weadejm.to_json,
        :headers => {
          'Content-Type' => 'application/json'
        }
      }
      print @current_user["email"].to_s
      results =  HTTParty.post("http://192.168.99.101:3004/json/"+@current_user["email"], options)
      return results
    end

    def generateDay()
      weadejm = HTTParty.get("http://192.168.99.101:3000/by_user_id?userid="+ @current_user["id"].to_s)
      options = {
        :body => weadejm.to_json,
        :headers => {
          'Content-Type' => 'application/json'
        }
      }
      print @current_user["email"].to_s
      ruta = "http://192.168.99.101:3004/json2/"+@current_user["email"]
      ruta = ruta +"/"
      ruta = ruta +params[:d_0]
      ruta = ruta +"/"
      ruta = ruta +params[:m_0]
      ruta = ruta +"/"
      ruta = ruta +params[:a_0]
      ruta = ruta +"/"
      ruta = ruta +params[:d_1]
      ruta = ruta +"/"
      ruta = ruta +params[:m_1]
      ruta = ruta +"/"
      ruta = ruta +params[:a_1]
      results =  HTTParty.post(ruta, options)
      return results
    end

#############################
#    notifications_ms
#############################
#Function to create a notification
    def createNotification(user_id,subject, content, notification_key)
      parameters={id_user: (user_id).to_i, subject: subject.to_s, content: content.to_s, notification_key: notification_key.to_s}
      options = {
        :body => parameters.to_json,
        :headers => {
          'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.post("http://192.168.99.101:3002/notifications", options)
      return results
    end

#Function to update a notification
    def updateNotification(subject, content, read, delivered)
      read = convertToBoolean(read)
      delivered = convertToBoolean(delivered)

      parameters={id_user: (@current_user["id"]).to_i, subject: subject.to_s, content: content.to_s, read: read, delivered: delivered   }
      options = {
        :body => params.to_json,
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.put("http://192.168.99.101:3002/notifications/"+@current_user["id"], options)
      render json: results.parsed_response, status: results.code
    end

    def convertToBoolean(v)
      if v.to_s == 'true'
        v = true
      elsif v.to_s == 'false'
        v = false
      end
      return v
    end

end
