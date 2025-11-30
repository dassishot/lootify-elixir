defmodule LootifyUsers.Guardian do
  @moduledoc """
  Guardian module para autenticação JWT.
  """
  use Guardian, otp_app: :lootify_users

  alias LootifyUsers.Users

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Users.get_user(id) do
      {:ok, user} -> {:ok, user}
      {:error, _} -> {:error, :resource_not_found}
    end
  end

  def resource_from_claims(_) do
    {:error, :invalid_claims}
  end
end
