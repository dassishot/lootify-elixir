defmodule LootifyWallets.Server do
  @moduledoc """
  GenServer que expõe as operações de wallet para outros serviços.
  Outros serviços no cluster podem chamar estas funções via:

      LootifyWallets.Server.reserve(user_id, amount, reference_id)

  O servidor se registra globalmente no cluster, permitindo
  comunicação transparente entre nós.
  """
  use GenServer
  require Logger

  alias LootifyWallets.Wallets

  # ============================================
  # Client API (chamada por outros serviços)
  # ============================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  end

  @doc """
  Cria uma wallet para um usuário.
  """
  def create_wallet(user_id) do
    GenServer.call({:global, __MODULE__}, {:create_wallet, user_id})
  end

  @doc """
  Adiciona crédito à wallet.
  """
  def credit(user_id, amount, reference_id, description \\ "Crédito") do
    GenServer.call({:global, __MODULE__}, {:credit, user_id, amount, reference_id, description})
  end

  @doc """
  Remove débito da wallet.
  """
  def debit(user_id, amount, reference_id, description \\ "Débito") do
    GenServer.call({:global, __MODULE__}, {:debit, user_id, amount, reference_id, description})
  end

  @doc """
  Reserva saldo para uma operação (ex: aposta).
  """
  def reserve(user_id, amount, reference_id, description \\ "Reserva") do
    GenServer.call({:global, __MODULE__}, {:reserve, user_id, amount, reference_id, description})
  end

  @doc """
  Libera saldo reservado (ex: aposta cancelada).
  """
  def release(user_id, reference_id, description \\ "Liberação") do
    GenServer.call({:global, __MODULE__}, {:release, user_id, reference_id, description})
  end

  @doc """
  Confirma reserva, removendo do locked (ex: aposta perdida).
  """
  def confirm(user_id, reference_id, description \\ "Confirmação") do
    GenServer.call({:global, __MODULE__}, {:confirm, user_id, reference_id, description})
  end

  @doc """
  Retorna o saldo de uma wallet.
  """
  def get_balance(user_id) do
    GenServer.call({:global, __MODULE__}, {:get_balance, user_id})
  end

  @doc """
  Busca wallet pelo user_id.
  """
  def get_wallet_by_user_id(user_id) do
    GenServer.call({:global, __MODULE__}, {:get_wallet_by_user_id, user_id})
  end

  # ============================================
  # Server Callbacks
  # ============================================

  @impl true
  def init(_opts) do
    Logger.info("LootifyWallets.Server started and registered globally")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:create_wallet, user_id}, _from, state) do
    result = Wallets.create_wallet(user_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:credit, user_id, amount, reference_id, description}, _from, state) do
    result = Wallets.credit(user_id, amount, reference_id, description)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:debit, user_id, amount, reference_id, description}, _from, state) do
    result = Wallets.debit(user_id, amount, reference_id, description)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:reserve, user_id, amount, reference_id, description}, _from, state) do
    result = Wallets.reserve(user_id, amount, reference_id, description)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:release, user_id, reference_id, description}, _from, state) do
    result = Wallets.release(user_id, reference_id, description)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:confirm, user_id, reference_id, description}, _from, state) do
    result = Wallets.confirm(user_id, reference_id, description)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_balance, user_id}, _from, state) do
    result = Wallets.get_balance(user_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_wallet_by_user_id, user_id}, _from, state) do
    result = Wallets.get_wallet_by_user_id(user_id)
    {:reply, result, state}
  end
end
