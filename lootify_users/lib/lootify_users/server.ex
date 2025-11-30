defmodule LootifyUsers.Server do
  @moduledoc """
  GenServer que expõe as operações de users para outros serviços.
  """
  use GenServer
  require Logger

  alias LootifyUsers.Users

  # ============================================
  # Client API
  # ============================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  end

  @doc """
  Registra um novo usuário.
  """
  def register(attrs) do
    GenServer.call({:global, __MODULE__}, {:register, attrs})
  end

  @doc """
  Autentica um usuário.
  """
  def authenticate(identifier, password) do
    GenServer.call({:global, __MODULE__}, {:authenticate, identifier, password})
  end

  @doc """
  Valida um token.
  """
  def validate_token(token) do
    GenServer.call({:global, __MODULE__}, {:validate_token, token})
  end

  @doc """
  Busca um usuário pelo ID.
  """
  def get_user(user_id) do
    GenServer.call({:global, __MODULE__}, {:get_user, user_id})
  end

  @doc """
  Busca um usuário pelo email.
  """
  def get_user_by_email(email) do
    GenServer.call({:global, __MODULE__}, {:get_user_by_email, email})
  end

  @doc """
  Atualiza o perfil de um usuário.
  """
  def update_profile(user_id, attrs) do
    GenServer.call({:global, __MODULE__}, {:update_profile, user_id, attrs})
  end

  @doc """
  Logout (revoga token).
  """
  def logout(token) do
    GenServer.call({:global, __MODULE__}, {:logout, token})
  end

  # ============================================
  # Server Callbacks
  # ============================================

  @impl true
  def init(_opts) do
    Logger.info("LootifyUsers.Server started and registered globally")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, attrs}, _from, state) do
    result = case Users.register(attrs) do
      {:ok, user} -> {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, format_changeset_errors(changeset)}
      {:error, reason} -> {:error, reason}
    end
    {:reply, result, state}
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @impl true
  def handle_call({:authenticate, identifier, password}, _from, state) do
    result = Users.authenticate(identifier, password)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:validate_token, token}, _from, state) do
    result = Users.validate_token(token)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_user, user_id}, _from, state) do
    result = Users.get_user(user_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_user_by_email, email}, _from, state) do
    result = Users.get_user_by_email(email)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:update_profile, user_id, attrs}, _from, state) do
    with {:ok, user} <- Users.get_user(user_id) do
      result = Users.update_profile(user, attrs)
      {:reply, result, state}
    else
      error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:logout, token}, _from, state) do
    result = Users.logout(token)
    {:reply, result, state}
  end
end
