Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

	# Authentication
	post "/users/register", to: "gateway#register"
	post "/users/login", to: "gateway#login"
	put "/users/update", to: "gateway#updateUser"

	# Credit Cards
	post "/credit_cards/registercard", to: "gateway#registerCard"
	put "/credit_cards", to: "gateway#updateCard"
	post "/credit_cards/transfer_money_from_card", to: "gateway#transferMoneyFromCard"
	delete "/credit_cards", to: "gateway#deleteCard"
	get "/credit_cards", to: "gateway#cardsByUser"

		# Transactions
	post "/create_transaction", to: "gateway#createTransaction"
	get "/transaction_by_user", to: "gateway#transactionByUser"

	# List
	post "/lists", to: "gateway#createItemOfList"
	get "/lists/by_user", to: "gateway#showListPendingPays"
	put "/lists", to: "gateway#updatePendingPay"
	delete "/lists", to: "gateway#deletePendingPay"

	# Notifications
	#post "/notifications", to: "gateway#createNotification"
	put "/notifications", to: "gateway#updateNotification"

end
