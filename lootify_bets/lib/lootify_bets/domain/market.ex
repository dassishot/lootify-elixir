defmodule LootifyBets.Domain.Market do
  @moduledoc """
  Schema para mercados de apostas (ex: vencedor, over/under, etc).
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias LootifyBets.Domain.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:open, :suspended, :closed, :settled]

  schema "markets" do
    field :name, :string
    field :type, :string
    field :status, Ecto.Enum, values: @statuses, default: :open
    field :odds, :decimal
    field :result, :string

    belongs_to :event, Event

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def create_changeset(market, attrs) do
    market
    |> cast(attrs, [:event_id, :name, :type, :status, :odds])
    |> validate_required([:event_id, :name, :type, :odds])
    |> validate_number(:odds, greater_than: 1)
    |> foreign_key_constraint(:event_id)
  end

  def update_odds_changeset(market, odds) do
    market
    |> change(odds: odds)
    |> validate_number(:odds, greater_than: 1)
  end

  def update_status_changeset(market, status) do
    market
    |> change(status: status)
    |> validate_inclusion(:status, @statuses)
  end

  def settle_changeset(market, result) do
    market
    |> change(status: :settled, result: result)
  end

  def open?(%__MODULE__{status: :open}), do: true
  def open?(_), do: false
end
