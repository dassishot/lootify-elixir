defmodule LootifyUsers.Users do
  @moduledoc """
  Contexto de Users - contém toda a lógica de negócio.
  """

  import Ecto.Query
  alias LootifyUsers.Repo
  alias LootifyUsers.Domain.User
  alias LootifyUsers.Guardian

  # ============================================
  # Queries
  # ============================================

  @doc """
  Busca um usuário pelo ID.
  """
  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Busca um usuário pelo email.
  """
  def get_user_by_email(email) do
    email = String.downcase(email)
    query = from u in User, where: u.email == ^email

    case Repo.one(query) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Busca um usuário pelo username.
  """
  def get_user_by_username(username) do
    username = String.downcase(username)
    query = from u in User, where: u.username == ^username

    case Repo.one(query) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Busca um usuário por email ou username.
  """
  def get_user_by_email_or_username(identifier) do
    identifier = String.downcase(identifier)

    query =
      from u in User,
        where: u.email == ^identifier or u.username == ^identifier

    case Repo.one(query) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  # ============================================
  # Commands
  # ============================================

  @doc """
  Registra um novo usuário.
  Retorna {:ok, user} ou {:error, changeset}.
  """
  def register(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Atualiza o perfil de um usuário.
  """
  def update_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Altera a senha de um usuário.
  """
  def change_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Atualiza o status de um usuário.
  """
  def update_status(user, status) do
    user
    |> User.status_changeset(%{status: status})
    |> Repo.update()
  end

  @doc """
  Marca o email como verificado.
  """
  def verify_email(user) do
    user
    |> User.verify_email_changeset()
    |> Repo.update()
  end

  # ============================================
  # Autenticação
  # ============================================

  @doc """
  Autentica um usuário por email/username e senha.
  Retorna {:ok, user, token} ou {:error, reason}.
  """
  def authenticate(identifier, password) do
    with {:ok, user} <- get_user_by_email_or_username(identifier),
         true <- User.active?(user),
         true <- User.verify_password(user, password),
         {:ok, _user} <- update_last_login(user),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      {:ok, user, token}
    else
      {:error, :not_found} -> {:error, :invalid_credentials}
      false -> {:error, :invalid_credentials}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Valida um token JWT e retorna o usuário.
  """
  def validate_token(token) do
    case Guardian.resource_from_token(token) do
      {:ok, user, _claims} ->
        if User.active?(user) do
          {:ok, user}
        else
          {:error, :user_inactive}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Revoga um token (logout).
  """
  def logout(token) do
    Guardian.revoke(token)
  end

  # ============================================
  # Helpers
  # ============================================

  defp update_last_login(user) do
    user
    |> User.login_changeset()
    |> Repo.update()
  end
end
