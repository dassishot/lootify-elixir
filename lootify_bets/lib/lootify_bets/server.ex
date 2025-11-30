defmodule LootifyBets.Server do
  @moduledoc """
  GenServer que expõe as operações de bets para outros serviços.
  """
  use GenServer
  require Logger

  alias LootifyBets.Bets

  # ============================================
  # Client API
  # ============================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  end

  # Events

  def list_events(filters \\ %{}) do
    GenServer.call({:global, __MODULE__}, {:list_events, filters})
  end

  def get_event(event_id) do
    GenServer.call({:global, __MODULE__}, {:get_event, event_id})
  end

  def create_event(attrs) do
    GenServer.call({:global, __MODULE__}, {:create_event, attrs})
  end

  # Markets

  def get_market(market_id) do
    GenServer.call({:global, __MODULE__}, {:get_market, market_id})
  end

  def create_market(attrs) do
    GenServer.call({:global, __MODULE__}, {:create_market, attrs})
  end

  def update_odds(market_id, odds) do
    GenServer.call({:global, __MODULE__}, {:update_odds, market_id, odds})
  end

  def get_current_odds(market_id) do
    # Leitura direta do cache (não passa pelo GenServer)
    LootifyBets.OddsCache.get(market_id)
  end

  # Bets

  def place_bet(user_id, market_id, amount, selection) do
    GenServer.call({:global, __MODULE__}, {:place_bet, user_id, market_id, amount, selection})
  end

  def cancel_bet(bet_id, user_id) do
    GenServer.call({:global, __MODULE__}, {:cancel_bet, bet_id, user_id})
  end

  def settle_bet(bet_id, result) do
    GenServer.call({:global, __MODULE__}, {:settle_bet, bet_id, result})
  end

  def get_bet(bet_id) do
    GenServer.call({:global, __MODULE__}, {:get_bet, bet_id})
  end

  def list_user_bets(user_id, filters \\ %{}) do
    GenServer.call({:global, __MODULE__}, {:list_user_bets, user_id, filters})
  end

  # ============================================
  # Server Callbacks
  # ============================================

  @impl true
  def init(_opts) do
    Logger.info("LootifyBets.Server started and registered globally")
    {:ok, %{}}
  end

  # Events

  @impl true
  def handle_call({:list_events, filters}, _from, state) do
    result = Bets.list_events(filters)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_event, event_id}, _from, state) do
    result = Bets.get_event(event_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:create_event, attrs}, _from, state) do
    result = Bets.create_event(attrs)
    {:reply, result, state}
  end

  # Markets

  @impl true
  def handle_call({:get_market, market_id}, _from, state) do
    result = Bets.get_market(market_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:create_market, attrs}, _from, state) do
    result = Bets.create_market(attrs)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:update_odds, market_id, odds}, _from, state) do
    result = Bets.update_odds(market_id, odds)
    {:reply, result, state}
  end

  # Bets

  @impl true
  def handle_call({:place_bet, user_id, market_id, amount, selection}, _from, state) do
    result = Bets.place_bet(user_id, market_id, amount, selection)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:cancel_bet, bet_id, user_id}, _from, state) do
    result = Bets.cancel_bet(bet_id, user_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:settle_bet, bet_id, result_status}, _from, state) do
    result = Bets.settle_bet(bet_id, result_status)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_bet, bet_id}, _from, state) do
    result = Bets.get_bet(bet_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_user_bets, user_id, filters}, _from, state) do
    result = Bets.list_user_bets(user_id, filters)
    {:reply, result, state}
  end
end
