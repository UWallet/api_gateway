Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	post "/users/register", to: "gateway#register"
	post "/users/login", to: "gateway#login"
	put "/users/update", to: "gateway#updateUser"
	post "/credit_cards/registercard", to: "gateway#registerCard"
	put "/credit_cards", to: "gateway#updateCard"
	put "/credit_cards/TranserMoneyFromCard", to: "gateway#TranserMoneyFromCard"
	delete "/credit_cards", to: "gateway#deleteCard"
	get "/credit_cards", to: "gateway#CardsByUser"
	get "/foo", to: "gateway#foo"
	post "/create_transaction", to: "gateway#createTransaction"
	get "/transaction_by_user", to: "gateway#transactionByUser"
	post "/lists", to: "gateway#CreateItemOfList"
	get "/lists/by_user", to: "gateway#showListPendingPays"
	put "/lists", to: "gateway#updatePendingPay"
	delete "/lists", to: "gateway#deletePendingPay"

end
