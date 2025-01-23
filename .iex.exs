import ExUnit.Assertions
import IEx.Helpers

alias Tictactemoji.Game

import_if_available(Ecto.Query)
import_if_available(Ecto.Query, only: [from: 2])
import_if_available(Ecto.Changeset)

defmodule Iex do
  def cpu_game() do
    {:ok, game} = Game.new_game_id() |> Game.new()
    {:ok, game} = Game.set_options(game, num_players: 3)
    {:ok, _, game} = Game.add_human_player(game)
    {:ok, game} = Game.add_cpu_players(game)
    game
  end

  def human_game() do
    {:ok, game} = Game.new_game_id() |> Game.new()
    {:ok, game} = Game.set_options(game, num_players: 3)
    {:ok, _, game} = Game.add_human_player(game)
    {:ok, _, game} = Game.add_human_player(game)
    {:ok, _, game} = Game.add_human_player(game)
    game
  end
end
