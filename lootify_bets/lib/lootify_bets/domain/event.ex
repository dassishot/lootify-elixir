defmodule LootifyBets.Domain.Event do
  @moduledoc """
  Schema para eventos de apostas (jogos, partidas, etc).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:scheduled, :live, :finished, :canceled]

  schema "events" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :status, Ecto.Enum, values: @statuses, default: :scheduled
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :metadata, :map, default: %{}

    has_many :markets, LootifyBets.Domain.Market

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def create_changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :description, :category, :status, :starts_at, :ends_at, :metadata])
    |> validate_required([:name, :category, :starts_at])
    |> validate_length(:name, max: 200)
    |> validate_inclusion(:status, @statuses)
  end

  def update_status_changeset(event, status) do
    event
    |> change(status: status)
    |> validate_inclusion(:status, @statuses)
  end

  def live?(%__MODULE__{status: :live}), do: true
  def live?(_), do: false

  def open_for_betting?(%__MODULE__{status: status}) when status in [:scheduled, :live], do: true
  def open_for_betting?(_), do: false
end
