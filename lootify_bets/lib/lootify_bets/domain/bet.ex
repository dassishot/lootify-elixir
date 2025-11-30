defmodule LootifyBets.Domain.Bet do
  @moduledoc """
  Schema para apostas dos usuários.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias LootifyBets.Domain.{Event, Market}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:pending, :won, :lost, :canceled, :cashout]

  schema "bets" do
    field :user_id, :binary_id
    field :amount, :decimal
    field :odds, :decimal
    field :potential_win, :decimal
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :settled_at, :utc_datetime
    field :selection, :string

    belongs_to :event, Event
    belongs_to :market, Market

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def create_changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :event_id, :market_id, :amount, :odds, :selection])
    |> validate_required([:user_id, :event_id, :market_id, :amount, :odds, :selection])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:odds, greater_than: 1)
    |> calculate_potential_win()
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:market_id)
  end

  def settle_changeset(bet, :won) do
    bet
    |> change(status: :won, settled_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def settle_changeset(bet, :lost) do
    bet
    |> change(status: :lost, settled_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def cancel_changeset(bet) do
    bet
    |> change(status: :canceled, settled_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp calculate_potential_win(changeset) do
    case {get_field(changeset, :amount), get_field(changeset, :odds)} do
      {amount, odds} when not is_nil(amount) and not is_nil(odds) ->
        potential = Decimal.mult(amount, odds)
        put_change(changeset, :potential_win, potential)

      _ ->
        changeset
    end
  end

  def pending?(%__MODULE__{status: :pending}), do: true
  def pending?(_), do: false

  def can_cancel?(%__MODULE__{status: :pending}), do: true
  def can_cancel?(_), do: false
end
