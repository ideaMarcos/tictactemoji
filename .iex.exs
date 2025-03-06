import ExUnit.Assertions
import IEx.Helpers
import Nx, only: :sigils

alias Tictactemoji.AxonCache
alias Tictactemoji.Cpu
alias Tictactemoji.Game
alias Tictactemoji.Model
alias Tictactemoji.TrainingData

import_if_available(Ecto.Query)
import_if_available(Ecto.Query, only: [from: 2])
import_if_available(Ecto.Changeset)

defmodule Cmdr do
  def human_game(num_players) do
    {:ok, game} = Game.new_game_id() |> Game.new()
    {:ok, game} = Game.set_options(game, num_players: 3)

    Enum.reduce(1..num_players, game, fn _, game ->
      {:ok, _, game} = Game.add_human_player(game)
      game
    end)
  end
end
