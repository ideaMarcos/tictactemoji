defmodule Tictactemoji.Cpu do
  alias Tictactemoji.Game

  def choose_position(%Game{} = game) do
    open_positions = Game.open_positions(game)

    find_winning_move(game, open_positions) ||
      any_open_positions?(open_positions)
  end

  defp any_open_positions?(open_positions) do
    open_positions
    |> Enum.random()
    |> IO.inspect(label: "-------------ANY_OPEN_POSITION")
  end

  defp find_winning_move(%Game{} = game, open_positions) do
    do_find_winning_move(game, open_positions, 1)
  end

  defp do_find_winning_move(%Game{} = game, open_positions, _depth) do
    open_positions
    |> Stream.filter(fn x ->
      {:ok, new_game} = Game.mark_position(game, x)
      Game.current_player_won?(new_game)
    end)
    |> Enum.to_list()
    |> List.first()
    |> IO.inspect(label: "-------------WINNING_POSITION")
  end
end
