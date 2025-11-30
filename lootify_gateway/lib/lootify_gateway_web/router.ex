defmodule LootifyGatewayWeb.Router do
  use LootifyGatewayWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Corsica, origins: "*", allow_headers: :all
  end

  pipeline :authenticated do
    plug LootifyGatewayWeb.Plugs.Auth
  end

  # Rotas públicas
  scope "/api", LootifyGatewayWeb do
    pipe_through :api

    # Auth
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login

    # Eventos (públicos)
    get "/events", EventController, :index
    get "/events/:id", EventController, :show
  end

  # Rotas autenticadas
  scope "/api", LootifyGatewayWeb do
    pipe_through [:api, :authenticated]

    # Auth
    get "/auth/me", AuthController, :me
    post "/auth/logout", AuthController, :logout

    # Wallet
    get "/wallet/balance", WalletController, :balance
    post "/wallet/deposit", WalletController, :deposit

    # Bets
    get "/bets", BetController, :index
    get "/bets/:id", BetController, :show
    post "/bets", BetController, :create
    delete "/bets/:id", BetController, :cancel
  end

  # Health check
  scope "/", LootifyGatewayWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end
end
