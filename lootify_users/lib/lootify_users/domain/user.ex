defmodule LootifyUsers.Domain.User do
  @moduledoc """
  Schema e lógica de domínio para User.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :first_name, :string
    field :last_name, :string
    field :status, Ecto.Enum, values: [:active, :inactive, :suspended], default: :active
    field :email_verified, :boolean, default: false
    field :last_login_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @required_fields [:email, :username, :password]
  @optional_fields [:first_name, :last_name, :status, :email_verified]

  @doc """
  Changeset para registro de um novo usuário.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_email()
    |> validate_username()
    |> validate_password()
    |> hash_password()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  Changeset para atualização de perfil.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name])
    |> validate_length(:first_name, max: 100)
    |> validate_length(:last_name, max: 100)
  end

  @doc """
  Changeset para alteração de senha.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> hash_password()
  end

  @doc """
  Changeset para atualização de status.
  """
  def status_changeset(user, attrs) do
    user
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, [:active, :inactive, :suspended])
  end

  @doc """
  Changeset para marcar último login.
  """
  def login_changeset(user) do
    user
    |> change(last_login_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset para verificar email.
  """
  def verify_email_changeset(user) do
    user
    |> change(email_verified: true)
  end

  # Validações privadas

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "deve ter formato válido")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "só pode conter letras, números e underscore")
    |> validate_length(:username, min: 3, max: 30)
    |> update_change(:username, &String.downcase/1)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72, message: "deve ter entre 8 e 72 caracteres")
    |> validate_format(:password, ~r/[a-z]/, message: "deve conter pelo menos uma letra minúscula")
    |> validate_format(:password, ~r/[A-Z]/, message: "deve conter pelo menos uma letra maiúscula")
    |> validate_format(:password, ~r/[0-9]/, message: "deve conter pelo menos um número")
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  @doc """
  Verifica se a senha está correta.
  """
  def verify_password(%__MODULE__{password_hash: hash}, password) when is_binary(password) do
    Pbkdf2.verify_pass(password, hash)
  end

  def verify_password(_, _), do: false

  @doc """
  Retorna o nome completo do usuário.
  """
  def full_name(%__MODULE__{first_name: first, last_name: last}) do
    [first, last]
    |> Enum.filter(&(&1 != nil and &1 != ""))
    |> Enum.join(" ")
    |> case do
      "" -> nil
      name -> name
    end
  end

  @doc """
  Verifica se o usuário está ativo.
  """
  def active?(%__MODULE__{status: :active}), do: true
  def active?(_), do: false
end
