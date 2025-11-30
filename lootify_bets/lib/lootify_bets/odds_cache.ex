defmodule LootifyBets.OddsCache do
  @moduledoc """
  Cache de odds em ETS para acesso ultra-rápido.
  Odds são atualizadas frequentemente e lidas milhares de vezes por segundo.
  """
  use GenServer
  require Logger

  @table :odds_cache

  # ============================================
  # Client API
  # ============================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Busca a odd atual de um mercado.
  Retorna {:ok, odds} ou {:error, :not_found}.
  Leitura direta da ETS (~0.001ms).
  """
  def get(market_id) do
    case :ets.lookup(@table, market_id) do
      [{^market_id, odds, _updated_at}] -> {:ok, odds}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Atualiza a odd de um mercado.
  Também notifica todos os clientes via PubSub.
  """
  def put(market_id, odds) do
    GenServer.cast(__MODULE__, {:put, market_id, odds})
  end

  @doc """
  Remove uma odd do cache.
  """
  def delete(market_id) do
    GenServer.cast(__MODULE__, {:delete, market_id})
  end

  @doc """
  Carrega todas as odds do banco para o cache.
  """
  def load_from_db do
    GenServer.call(__MODULE__, :load_from_db)
  end

  @doc """
  Retorna todas as odds do cache (para debug).
  """
  def all do
    :ets.tab2list(@table)
  end

  # ============================================
  # Server Callbacks
  # ============================================

  @impl true
  def init(_opts) do
    # Cria tabela ETS com leitura concorrente
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    Logger.info("OddsCache initialized")

    # Carrega odds do banco na inicialização
    send(self(), :load_initial_data)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:load_initial_data, state) do
    load_odds_from_database()
    {:noreply, state}
  end

  @impl true
  def handle_cast({:put, market_id, odds}, state) do
    now = DateTime.utc_now()
    :ets.insert(@table, {market_id, odds, now})

    # Notifica via PubSub
    Phoenix.PubSub.broadcast(
      LootifyBets.PubSub,
      "odds:#{market_id}",
      {:odds_updated, market_id, odds}
    )

    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete, market_id}, state) do
    :ets.delete(@table, market_id)
    {:noreply, state}
  end

  @impl true
  def handle_call(:load_from_db, _from, state) do
    count = load_odds_from_database()
    {:reply, {:ok, count}, state}
  end

  # ============================================
  # Helpers
  # ============================================

  defp load_odds_from_database do
    alias LootifyBets.Repo
    alias LootifyBets.Domain.Market
    import Ecto.Query

    markets =
      from(m in Market, where: m.status == :open, select: {m.id, m.odds})
      |> Repo.all()

    now = DateTime.utc_now()

    Enum.each(markets, fn {id, odds} ->
      :ets.insert(@table, {id, odds, now})
    end)

    Logger.info("Loaded #{length(markets)} odds into cache")
    length(markets)
  end
end
