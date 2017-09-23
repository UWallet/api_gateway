Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	post "/users/register", to: "gateway#register"
	post "/users/login", to: "gateway#login"
	get "/foo", to: "gateway#foo"
	post "/createtransaction", to: "gateway#createTransaction"
end
