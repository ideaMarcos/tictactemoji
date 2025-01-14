defmodule Tictactemoji.Cpu do
  require Integer
  alias Tictactemoji.Game

  def choose_position(%Game{} = game) do
    find_best_position(game) ||
      any_open_positions?(game)
  end

  defp any_open_positions?(%Game{} = game) do
    Game.open_positions(game)
    |> Enum.random()
  end

  defp find_best_position(%Game{} = game) do
    current_player = game.current_player

    for position <- Game.open_positions(game), player_index <- 0..(game.num_players - 1) do
      {:ok, new_game} =
        game
        |> Game.set_current_player(player_index)
        |> Game.mark_position(position)

      if Game.current_player_won?(new_game) do
        score = if player_index == current_player, do: game.sequence_size, else: 1
        {score, position}
      else
        {0, nil}
      end
    end
    |> Enum.sort(:desc)
    |> List.first()
    # |> IO.inspect(label: "-------------WINNING_POSITION")
    |> elem(1)
  end
end
