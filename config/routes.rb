Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	post "/users/register", to: "gateway#register"
	post "/users/login", to: "gateway#login"
	post "/credit_cards/registercard", to: "gateway#registerCard"
	put "/credit_cards", to: "gateway#updateCard"
	delete "/credit_cards", to: "gateway#deleteCard"
	get "/foo", to: "gateway#foo"


end
