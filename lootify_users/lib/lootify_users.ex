defmodule LootifyUsers do
  @moduledoc """
  LootifyUsers - Serviço de usuários para o sistema Lootify.

  Este serviço é responsável por:
  - Registro de usuários
  - Autenticação (login/logout)
  - Gerenciamento de perfil
  - Validação de tokens JWT

  ## Uso por outros serviços

      # Registrar usuário
      LootifyUsers.Server.register(%{
        email: "user@example.com",
        username: "user123",
        password: "SecurePass123"
      })

      # Autenticar
      LootifyUsers.Server.authenticate("user@example.com", "SecurePass123")

      # Validar token
      LootifyUsers.Server.validate_token(token)

      # Buscar usuário
      LootifyUsers.Server.get_user(user_id)
  """

  defdelegate register(attrs), to: LootifyUsers.Users
  defdelegate authenticate(identifier, password), to: LootifyUsers.Users
  defdelegate validate_token(token), to: LootifyUsers.Users
  defdelegate get_user(id), to: LootifyUsers.Users
  defdelegate get_user_by_email(email), to: LootifyUsers.Users
  defdelegate update_profile(user, attrs), to: LootifyUsers.Users
  defdelegate logout(token), to: LootifyUsers.Users
end
