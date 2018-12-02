Rails.application.routes.draw do
  mount AnyCable::Rack => '/cable'
end
