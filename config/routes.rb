Cluster::Application.routes.draw do
  get "/posts/add", to: "posts#add"
  get "/posts/",    to: "posts#index"
end
