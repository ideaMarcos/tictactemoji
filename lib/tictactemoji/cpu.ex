defmodule Tictactemoji.Cpu do
  require Logger
  alias Tictactemoji.AxonCache
  alias Tictactemoji.Model
  alias Tictactemoji.Game

  def choose_position(%Game{} = game) do
    Enum.at(game.player_tokens, game.current_player)
    |> String.starts_with?(Game.simple_cpu_token())
    |> case do
      true -> simple_choice(game)
      false -> trained_choice(game)
    end
  end

  defp simple_choice(%Game{} = game) do
    win_or_block_win(game) ||
      take_center(game) ||
      random_position(game)
  end

  defp trained_choice(%Game{} = game) do
    model = Model.new(game.num_players)
    trained_state = AxonCache.get_state(game.move_count + 1)

    position =
      model
      |> Model.predict(trained_state, Game.to_nn_input_data(game))
      |> Enum.filter(fn x -> x in Game.open_positions(game) end)
      # |> IO.inspect(label: "trained_choice")
      |> List.first()

    # Logger.emergency(inspect({Game.to_nn_input_data(game), position}) <> ",")

    position
  end

  defp random_position(%Game{} = game) do
    Game.open_positions(game)
    |> Enum.random()
  end

  def take_center(%Game{} = game) do
    center =
      Game.calc_num_positions(game.grid_size)
      |> Integer.floor_div(2)

    if game.move_count < 3 && center in Game.open_positions(game) do
      center
    else
      nil
    end
  end

  def win_or_block_win(%Game{} = game) do
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
    |> Enum.max()
    |> elem(1)
  end

  def make_move(%Game{game_over?: true}) do
    {:error, :game_over}
  end

  def make_move(%Game{} = game) do
    if Game.is_cpu_move?(game) do
      position = choose_position(game)
      Game.mark_position(game, position)
    else
      {:error, :not_cpu_move}
    end
  end

  def play_until_game_over(%Game{} = game) do
    make_move(game)
    |> do_play_until_game_over(game)
  end

  defp do_play_until_game_over({:ok, game}, _) do
    play_until_game_over(game)
  end

  defp do_play_until_game_over({:error, :game_over}, game) do
    {:ok, :game_over, game}
  end
end
