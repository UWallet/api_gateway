class GatewayController < ApplicationController
  #Call back to requiere login
  before_action :authenticate_request!, only:[:logout,:updateUser, :verifyPass, :getUser, :registerCard, :updateCard, :deleteCard, :cardsByUser, :transactionByUser, :createTransaction,:createItemOfList,:updatePendingPay,:deletePendingPay, :showListPendingPays, :transferMoneyFromCard, :generateAll, :generateDays]
  PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQDqAMvO0w5Lz3iyJObftSw8jFo/3CoyqaYLcWbA6A4mjCufMie8\nL+dA8kKO1M4JpmslU1h7W1fovOUDNc4ZukhMN/PivfaqROZ95GwQfLWjkKRBngSU\n5ITOBtqAuiBSeJgfZORe4C4NoiVkssfTUUgmYbs7wj1k5Jz0K0e1odGHzQIDAQAB\nAoGBAKETGzerIFQe5D38GNA0rdaf5h+/NWzaSmnmDY0ML3FpWz2iEKgBcXXLTPV0\nlr8dxvNSg72mCsUyAZJMHyqmh8xeWX0fjqPdWJxfb6yriAru2Dzb/VFOdLfAyLiq\n1a9YG24FBeXGHYNI/0YW/YPBRiaW//MLKy37UIc2beBDwo8hAkEA+GNl0qbOJczm\nnTS6UL1nr2LSqJ87gjqmRxgA8HdyPexFhI/4W1sI0C3Vb6lgakerZnOkSR4NiyO+\nGCEdga7BuwJBAPEsjAfkM5S/GkwBYV3tHr2Znvc+r2/3ORr2Pqqpf8VNKUZoZ7jJ\nV1EodWUlpsydYIfXLKI3wkVHn0SmtxPoYBcCQHTfqEifLj7BE/4CkmxtQr1WvZKU\nIhcb66NmGwMK4Rlb9DX03EJ4KkRyXIyG4RQBFxhE75dr6al/rvGBm3WqugMCQCLs\nQnK6FsYJTjOHV6QUPAlUf3Jp/1mFQR2oXrazyK63V6y8XZiifyRfaXB2HUsv1tSU\n0f/Ddzw0/NkiEwys740CQHhEmL228QMBzKN5Rg3CyeLpHIRcxkj2N/XjbzY3UP3R\nf4VOiTXQCuLmGcib9G+v8jOhPbEJ4hWnhCAJHB9/h9c=\n-----END RSA PRIVATE KEY-----"
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
      parameters={user_id: (@current_user["id"]).to_i, description: (params[:description]), date_pay: params[:date_pay], cost: params[:cost], target_account: params[:target_account], state_pay:params[:state_pay]}
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
    @key_name_prefix="test5_"
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

#update gruopkey on user
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
      usr=params[:user]
      pass=encryptor(usr[:password])
      confPass=encryptor(usr[:password_confirmation])
      #puts(pass)
      #puts(usr[:password])
      @key_name_prefix="test5_"
      options = {
        :body =>{
                "firstName": usr[:firstName],
                "lastName": usr[:lastName],
                "email": usr[:email],
                "password": pass,
                "password_confirmation": confPass
              }.to_json,
        :headers => {'Content-Type'=> 'application/json'
                    }
      }
            #puts(options)
            resultsLDAP = HTTParty.post("http://192.168.99.101:4001/user/resources/ldapcruds", options)
            if resultsLDAP.code == 201
            #  options = {
            #    :body => params.to_json,
            #    :headers => {
            #    'Content-Type' => 'application/json'
            #    }
            #  }
            options = {
                :body =>{ "user":{
                        "firstName": usr[:firstName],
                        "lastName": usr[:lastName],
                        "email": usr[:email],
                        "password": pass,
                        "password_confirmation": confPass
                        }
                      }.to_json,
                :headers => {'Content-Type'=> 'application/json'
                            }
              }
              #puts(options)
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
          elsif resultsLDAP.code == 400
            render json: {"email": ["has already been taken"]}.to_json, status: 422
          else
            renderError("Not Avalible", 503, "OpenLDAP server conection failed")
          end
    end

#function to login users
    def login

      pass=(encryptor(params[:password]))
      #puts(pass)
      @key_name_prefix="test5_"

      options={}
      if params[:device_token] == nil
        options = {
          :body =>{"email": params[:email],
                   "password": pass
                  }.to_json,
          :headers => {'Content-Type'=> 'application/json'
                      }
        }
     else
      options = {
        :body =>{"email": params[:email],
                 "password": pass,
                 "device_token": params[:device_token]
                }.to_json,
        :headers => {'Content-Type'=> 'application/json'
                    }
      }
    end
      #puts(options)
      resultsLDAP = HTTParty.post("http://192.168.99.101:4001/user/resources/ldap", options)
      if resultsLDAP.code == 200
        results = HTTParty.post("http://192.168.99.101:3001/users/login", options)
            if results.code == 200
              if params[:device_token] == nil
                 render json: {auth_token: results.parsed_response["auth_token"]}.to_json, status: results.code
              return 1
             end
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
        elsif resultsLDAP.code == 401
          renderError("Unauthenticated",401,"Invalid username / password")
        else
          renderError("Not Avalible", 503, "OpenLDAP server conection failed")
        end
end

#function to logOut

  def logout
    @key_name_prefix="test5_"
    if params[:device_token] == nil
       call_logout()
    return 1
   end
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
      call_logout()
    else
      render json: results2.parsed_response, status: results2.code
    end
  end

#fuction to private logout

def call_logout
  options = {
    :headers => {'Authorization' => request.headers['Authorization'] }
  }
  results = HTTParty.get("http://192.168.99.101:3001/users/logout", options)
  if results.code == 204
    render json:{}.to_json, status: 200
  else
    render json: results.parsed_response, status: results.code
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

    def get_group_key(user)
      options = {
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      results = HTTParty.get("http://192.168.99.101:3001/group_keys/get_group_key?user_id="+user.to_s, options)
      return results.parsed_response["notification_key"]
    end

    #function to verify password
    def verifyPass
      pass=(encryptor(params[:password]))
      #puts(pass)
      options = {
        :body =>{"password": pass
                }.to_json,
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
      if results1.code == 201
        logTransaction("Transfer", transact["id"], @current_user["id"], @current_user["id"], params[:money], "initial", 0)
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
              logUpdateCard(params[:cardId], newMoneyCard, 0)
              results2 = updateTransaction("pending", transact["id"])# put pending state
              if results2.code == 204
                logTransaction("Transfer", transact["id"], @current_user["id"], @current_user["id"], params[:money], "pending", 0)
              else
                ##########ERROR EN UPDATE TRANSACCION (pending)###### Se devuelve el dinero a la tarjeta, state incomplete
                undoUpdateCard(params[:cardId], newMoneyCard.to_i , newMoneyCard.to_i + (params[:money]).to_i)
                resultsError = updateTransaction("incomplete", transact["id"])
                if resultsError.code == 204
                  logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
                end
                render json: results4.parsed_response, status: results4.code
                ##########ERROR EN UPDATE TRANSACCION (pending)###### Se devuelve el dinero a la tarjeta, state incomplete
              end
            else
              ##########ERROR EN UPDATE A TARJETA###### Se devuelve el dinero a la tarjeta, state incomplete
              undoUpdateCard(params[:cardId], newMoneyCard.to_i , newMoneyCard.to_i + (params[:money]).to_i)
              resultsError = updateTransaction("incomplete", transact["id"])
              if resultsError.code == 204
                logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
              end
              render json: resultCd.parsed_response, status: resultCd.code
              ##########ERROR EN UPDATE TRANSACCION (pending)###### Se devuelve el dinero a la tarjeta, state incomplete
            end
            resultUs = updateMoney(newMoneyUser, userA.to_s) #add money to user
            if resultUs.code == 204
              logUpdateMoney(userA.to_s, newMoneyUser, 0)
              results3 = updateTransaction("complete", transact["id"])# put complete state
              if results3.code == 204
                logTransaction("Transfer", transact["id"], @current_user["id"], @current_user["id"], params[:money], "complete", 0)
                subject = "Transferencia de tarjeta de credito"
                content = "Has recibido una transferencia de la cuenta " + params[:cardId].to_s + " por valor de $" + (params[:money]).to_s
                createNotification(@current_user["id"],subject, content, @current_user_notification_key)
                head 201 # transaction created and state complete
              else
                ##########ERROR EN UPDATE TRANSACCION (complete)###### Se devuelve el dinero a la tarjeta, y se le resta al usuario state incomplete
                #le quita al que recibe
                undoUpdateMoney(params[:userid], newMoneyUser.to_f , newMoneyUser.to_f - (params[:money]).to_i)
                #le pone dinero de nuevo a la tarjeta
                undoUpdateCard(params[:cardId], newMoneyCard.to_i , newMoneyCard.to_i + (params[:money]).to_i)
                resultsError = updateTransaction("incomplete", transact["id"])
                if resultsError.code == 204
                  logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
                end
                render json: results3.parsed_response, status: results3.code
                ##########ERROR EN UPDATE TRANSACCION (complete)###### Se devuelve el dinero a la tarjeta, y se le resta al usuario state incomplete
              end
            else
              ##########ERROR EN UPDATE MONEY###### Se devuelve el dinero a la tarjeta, y se le resta al usuario state incomplete
              #le quita al que recibe
              undoUpdateMoney(params[:userid], newMoneyUser.to_f , newMoneyUser.to_f - (params[:money]).to_i)
              #le pone dinero de nuevo a la tarjeta
              undoUpdateCard(params[:cardId], newMoneyCard.to_i , newMoneyCard.to_i + (params[:money]).to_i)
              resultsError = updateTransaction("incomplete", transact["id"])
              if resultsError.code == 204
                logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
              end
              render json: resultUs.parsed_response, status: resultUs.code
              ##########ERROR EN UPDATE MONEY######  Se devuelve el dinero a la tarjeta, y se le resta al usuario state incomplete
            end
          end
        end
      else
        resultsError = updateTransaction("incomplete", transact["id"])
        if resultsError.code == 204
          logTransaction("Transaction", transact["id"], @current_user["id"], @current_user["id"], params[:money], "incomplete", 1)
        end
        render json: results1.parsed_response, status: results1.code
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
      money1 = checkMoneyUser(@current_user["id"]) # check if the user id that sends the money have the amount
      moneyusergiving = money1.parsed_response
      if (moneyusergiving["money"]).to_f > 0 && (moneyusergiving["money"]).to_f >= (params[:amount]).to_f
        if results1.code == 200
          results2 = postTransaction(@current_user["id"], params[:userid], params[:amount]) # create initial state
          transact = results2.parsed_response # transact object to get the id in the rest of the process
          if results2.code == 201
            logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], transact["state"], 0)
            newMoneyGiving = (moneyusergiving["money"]).to_f - (params[:amount]).to_f
            results3 = updateMoney(newMoneyGiving, @current_user["id"]) #subtract money from useridgiving
            if results3.code == 204
              logUpdateMoney(@current_user["id"], newMoneyGiving, 0)
              results4 = updateTransaction("pending", transact["id"])# put pending state
              if results4.code == 204
                logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "pending", 0)
                money2 = checkMoneyUser(params[:userid]) # check if the user id that sends the money have the amount
                moneyuserreceiving= money2.parsed_response
                newMoneyReceiving = (moneyuserreceiving["money"]).to_f + (params[:amount]).to_f
                results5 = updateMoney(newMoneyReceiving, params[:userid])#add money from useridreceiving
                if results5.code == 204
                  logUpdateMoney(params[:userid], (moneyuserreceiving["money"]).to_f + (params[:amount]).to_f, 0)
                  results6 = updateTransaction("complete", transact["id"])# put complete state
                  if results6.code == 204
                    logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "complete", 0)
                    subject = "Transacción"
                    content = "Has recibido una transacción del usuario " + formato(@current_user["id"]) + " por valor de $" + (params[:amount]).to_s
                    notification_key = get_group_key(params[:userid])
                    createNotification(params[:userid],subject, content, notification_key)
                    head 201 # transaction created and state #####COMPLETE#######
                  else
                    ##########ERROR EN UPDATE A TRANSACCION (complete)###### Si ya se le resto el dinero se le devuelve y  al otro usuario si se le sumo se le resta.
                    #devuelve el dinero al que envia
                    undoUpdateMoney(@current_user["id"], newMoneyGiving.to_f , newMoneyGiving.to_f + (params[:amount]).to_f)
                    #le quita al que recibe
                    undoUpdateMoney(params[:userid], newMoneyReceiving.to_f , newMoneyReceiving.to_f - (params[:amount]).to_f)
                    resultsError = updateTransaction("incomplete", transact["id"])
                    if resultsError.code == 204
                      logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
                    end
                    render json: results6.parsed_response, status: results6.code
                    ##########ERROR EN UPDATE A TRANSACCION (complete)###### Si ya se le resto el dinero se le devuelve y  al otro usuario si se le sumo se le resta.
                  end
                else
                  ##########ERROR EN SUMAR DINERO AL DESTINATARIO###### Si ya se le resto el dinero se le devuelve y  al otro usuario si se le sumo se le resta.
                  #devuelve el dinero al que envia
                  undoUpdateMoney(@current_user["id"], newMoneyGiving.to_f , newMoneyGiving.to_f + (params[:amount]).to_f)
                  #le quita al que recibe
                  undoUpdateMoney(params[:userid], newMoneyReceiving.to_f , newMoneyReceiving.to_f - (params[:amount]).to_f)
                  resultsError = updateTransaction("incomplete", transact["id"])
                  if resultsError.code == 204
                    logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
                  end
                  render json: results5.parsed_response, status: results5.code
                  ##########ERROR EN SUMAR DINERO AL DESTINATARIO###### Si ya se le resto el dinero se le devuelve y si se le sumo se le resta.
                end
              else
                ##########ERROR EN UPDATE A TRANSACCION (pending)###### Si ya se le resto el dinero se le devuelve y si se le sumo se le resta.
                undoUpdateMoney(@current_user["id"], newMoneyGiving.to_f , newMoneyGiving.to_f + (params[:amount]).to_f)
                resultsError = updateTransaction("incomplete", transact["id"])
                if resultsError.code == 204
                  logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
                end
                render json: results4.parsed_response, status: results4.code
                ##########ERROR EN UPDATE A TRANSACCION (pending)###### Si ya se le resto el dinero se le devuelve y si se le sumo se le resta.
              end
            else
              ##########ERROR EN RESTAR DINERO AL USUARIO QUE ENVIA###### Si ya se le resto el dinero se le devuelve y se deja la transaccion como incomplete
              undoUpdateMoney(@current_user["id"], newMoneyGiving.to_f , newMoneyGiving.to_f + (params[:amount]).to_f)
              resultsError = updateTransaction("incomplete", transact["id"])
              if resultsError.code == 204
                logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
              end
              render json: results3.parsed_response, status: results3.code
              ##########ERROR EN RESTAR DINERO AL USUARIO QUE ENVIA###### Si ya se le resto el dinero se le devuelve y se deja la transaccion como incomplete
            end
          else
            resultsError = updateTransaction("incomplete", transact["id"])
            if resultsError.code == 204
              logTransaction("Transaction", transact["id"], @current_user["id"], params[:userid], params[:amount], "incomplete", 1)
            end
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

    #funcion que maneja las acciones correctoras con el dinero en el USUARIO, duelve el dinero o lo quita a quien corresponda
    def undoUpdateMoney(userid, expectedMoney,fixedMoney)
      money1 = checkMoneyUser(userid)
      moneyuser = money1.parsed_response
      if expectedMoney == (moneyuser["money"]).to_f
        resultsUndo = updateMoney(fixedMoney , userid)
        if resultsUndo.code == 204
          logUpdateMoney(userid, fixedMoney, 1)
        end
      end
    end

    #funcion que maneja las acciones correctoras con el dinero en las TARJETAS, duelve el dinero o lo quita a quien corresponda
    def undoUpdateCard(cardid, expectedMoney,fixedMoney)
      resultsGet = HTTParty.get("http://192.168.99.101:3003/credit_card?id="+cardid.to_s)
      if expectedMoney == resultsGet["amount"].to_i
        optionsCd = {
          :body => {"amount": fixedMoney}.to_json,
          :headers => {
          'Content-Type' => 'application/json',
          'Authorization' => request.headers['Authorization']
          }
        }
        resultCd = HTTParty.put("http://192.168.99.101:3003/credit_cards?id="+params[:cardId].to_s, optionsCd)
        if resultCd.code == 204
          logUpdateCard(cardid, fixedMoney, 1)
        end
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
      parameters={id_user: (user_id).to_i, subject: subject.to_s, content: content.to_s, notification_key: notification_key.to_s, delivered: false, read: false}
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
    def updateNotification
      read = convertToBoolean(read)
      delivered = convertToBoolean(delivered)

      parameters={id_user: params[:id_user].to_i, subject: params[:subject].to_s, content: params[:content].to_s, read: params[:read], delivered: params[:delivered]   }
      options = {
        :body => parameters.to_json,
        :headers => {
        'Content-Type' => 'application/json'
        }
      }
      url = "http://192.168.99.101:3002/notifications/"+params[:id].to_s
      results = HTTParty.put(url.to_s, options)
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
    # Desencriptacion
    def encryptor(data)
      private_key = OpenSSL::PKey::RSA.new(PRIVATE_KEY)
      private_key.private_decrypt(Base64.decode64(data))
    end

    def logTransaction(tipo, transactid, giving, receiving, amount, state, error)
      if error==1
        MyLog.log.error "Error! #{tipo} #{transactid} #{giving} #{receiving} #{amount} #{state}"
      else
        MyLog.log.debug("Correcto! #{tipo} #{transactid} #{giving} #{receiving} #{amount} #{state}")
      end
      file = File.open("logapp.log","r")

      #file.each_line do |line|
      #    puts line
      #end
      #file.close
      return true
    end

    def logUpdateMoney(userid, amount, error)
      if error==1
        MyLog.log.error "Error! UpdateMoneyUser #{userid} #{amount}"
      else
        MyLog.log.debug("Correcto! UpdateMoneyUser #{userid} #{amount}")
      end
      file = File.open("logapp.log","r")

      #file.each_line do |line|
      #    puts line
      #end
      #file.close
      return true
    end

    def logUpdateCard(cardid, amount, error)
      if error==1
        MyLog.log.error "Error! UpdateCard #{cardid} #{amount}"
      else
        MyLog.log.debug("Correcto! UpdateCard #{cardid} #{amount}")
      end
      file = File.open("logapp.log","r")

      #file.each_line do |line|
      #    puts line
      #end
      #file.close
      return true
    end

end




require 'logger'
class OpenLog
  def initialize(*targets)
    @targets = targets
  end

  def self.delegate(*methods)
    methods.each do |m|
      define_method(m) do |*args|
        @targets.map { |t| t.send(m, *args) }
      end
    end
    self
  end

  class <<self
    alias to new
  end
end

class MyLog
  def self.log
    if @logger.nil?
      if File.file?("logapp.log")
        log_file = File.open("logapp.log", "a")
        @logger = Logger.new OpenLog.delegate(:write, :close).to(STDOUT, log_file)
      else
        @logger = Logger.new 'logapp.log'
      end
    end
    @logger
  end
end
