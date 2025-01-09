defmodule Tictactemoji.Schema.GameOptions do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :grid_size, :integer, default: 3
    field :num_players, :integer, default: 2
  end

  def new(), do: %__MODULE__{}

  def changeset(%__MODULE__{} = game, attrs) do
    game
    |> cast(attrs, [:grid_size, :num_players])
    |> validate_required([:grid_size, :num_players])
    |> validate_number(:grid_size, greater_than_or_equal_to: 3, less_than_or_equal_to: 11)
    |> validate_number(:num_players, greater_than_or_equal_to: 1, less_than_or_equal_to: 7)
  end

  def apply_update_action(changeset), do: apply_action(changeset, :update)
end
