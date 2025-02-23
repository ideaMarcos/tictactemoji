defmodule Tictactemoji.Game do
  require Logger

  ### Representation of the tic tac toe grid with rows = @grid_size and columns = @grid_size will be a list
  ### of size @grid_size ^ 2
  ###
  ### 0 | 1 | 2
  ### 3 | 4 | 5
  ### 6 | 7 | 8
  ###
  ### OR
  ###
  ###  0 |  1 |  2 |  3 |  4
  ###  5 |  6 |  7 |  8 |  9
  ### 10 | 11 | 12 | 13 | 14
  ### 15 | 16 | 17 | 18 | 19
  ### 20 | 21 | 22 | 23 | 24

  @unplayed_position -1
  @simple_cpu_token "CPU_SMPL"
  @trained_cpu_token "CPU_TRAIN"

  defstruct id: nil,
            grid_size: nil,
            sequence_size: nil,
            num_players: nil,
            current_player: nil,
            player_tokens: nil,
            player_emojis: nil,
            sparse_grid: nil,
            game_over?: nil,
            result: nil,
            history: nil,
            move_count: nil

  def new(game_id) do
    game = %__MODULE__{
      id: game_id,
      player_tokens: [],
      player_emojis: []
    }

    {:ok, game}
  end

  def new_game_id do
    Enum.take_random(~c/ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/, 9)
    |> to_string()
  end

  def set_options(%__MODULE__{} = game, options) when is_list(options) do
    if game.player_tokens == [] do
      do_set_options(game, options)
    else
      {:error, :game_already_started}
    end
  end

  defp do_set_options(%__MODULE__{} = game, options) do
    num_players = Keyword.get(options, :num_players)
    grid_size = calc_grid_size(num_players)

    {:ok,
     %{
       game
       | grid_size: grid_size,
         sequence_size: 3,
         num_players: num_players,
         player_emojis: Enum.take_random(~c"🐶🐱🐭🐰🦊🐻🐼🐨🦁🐮🐷🐸", num_players)
     }}
  end

  def calc_grid_size(num_players) do
    num_players + 1
  end

  def calc_num_positions(grid_size) do
    Integer.pow(grid_size, 2)
  end

  defp start_game_if_ready(%__MODULE__{} = game) do
    if ready?(game) do
      reset_game(game)
    else
      game
    end
  end

  def reset_game(%__MODULE__{game_over?: false} = game), do: game

  def reset_game(%__MODULE__{} = game) do
    player_order = Enum.shuffle(0..(game.num_players - 1))

    %{
      game
      | current_player: 0,
        game_over?: false,
        player_tokens: Enum.map(player_order, fn x -> Enum.at(game.player_tokens, x) end),
        player_emojis: Enum.map(player_order, fn x -> Enum.at(game.player_emojis, x) end),
        sparse_grid:
          List.duplicate(@unplayed_position, game.sequence_size)
          |> List.duplicate(game.num_players),
        history: List.duplicate([], game.num_players),
        move_count: 0,
        result: nil
    }
  end

  def ready?(%__MODULE__{} = game) do
    length(game.player_tokens) == game.num_players
  end

  def add_human_player(%__MODULE__{} = game) do
    if length(game.player_tokens) >= game.num_players do
      {:error, :too_many_players}
    else
      token =
        Enum.take_random(~c/ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/, 5)
        |> to_string()

      {:ok, token,
       %{game | player_tokens: [token | game.player_tokens]}
       |> start_game_if_ready()}
    end
  end

  def add_cpu_player(%__MODULE__{} = game, trained?) do
    token = if trained?, do: @trained_cpu_token, else: @simple_cpu_token
    token = "#{token}_#{length(game.player_tokens) + 1}"
    game = %{game | player_tokens: [token | game.player_tokens]}
    {:ok, start_game_if_ready(game)}
  end

  def add_cpu_players(%__MODULE__{} = game, trained?) do
    remaining = game.num_players - length(game.player_tokens)

    new_game =
      Enum.reduce(1..remaining, game, fn _, new_game ->
        {:ok, new_game} = add_cpu_player(new_game, trained?)
        new_game
      end)

    {:ok, start_game_if_ready(new_game)}
  end

  def mark_position(%__MODULE__{game_over?: true}, _), do: {:error, :game_over}

  def mark_position(%__MODULE__{} = game, position) do
    if game.game_over? do
      {:error, :game_over}
    else
      if playable_position?(game, position) do
        new_current_positions =
          Enum.at(game.sparse_grid, game.current_player)
          |> Enum.concat([position])
          |> Enum.take(-game.sequence_size)

        new_sparse_grid =
          List.replace_at(game.sparse_grid, game.current_player, new_current_positions)

        current_player_history =
          Enum.at(game.history, game.current_player)
          |> Enum.concat([{to_nn_input_data(game), position}])

        new_history =
          List.replace_at(game.history, game.current_player, current_player_history)

        result =
          cond do
            current_player_won?(%{game | sparse_grid: new_sparse_grid}) -> :win
            Integer.floor_div(game.move_count, game.num_players) > 50 -> :tie
            true -> nil
          end

        game_over? = result != nil

        current_player =
          if game_over? do
            game.current_player
          else
            rem(game.current_player + 1, game.num_players)
          end

        {:ok,
         %{
           game
           | current_player: current_player,
             history: new_history,
             sparse_grid: new_sparse_grid,
             game_over?: game_over?,
             result: result,
             move_count: game.move_count + 1
         }}
      else
        {:error, :position_already_taken}
      end
    end
  end

  def simple_cpu_token, do: @simple_cpu_token
  def trained_cpu_token, do: @trained_cpu_token

  def get_first_human_player_index(%__MODULE__{} = game) do
    game.player_tokens
    |> Enum.find_index(fn x -> not String.starts_with?(x, @simple_cpu_token) end)
  end

  def is_cpu_move?(%__MODULE__{current_player: nil}), do: false
  def is_cpu_move?(%__MODULE__{game_over?: true}), do: false

  def is_cpu_move?(%__MODULE__{} = game) do
    token =
      game.player_tokens
      |> Enum.at(game.current_player)

    cond do
      String.starts_with?(token, @simple_cpu_token) -> true
      String.starts_with?(token, @trained_cpu_token) -> true
      true -> false
    end
  end

  def playable_position?(%__MODULE__{} = game, position) do
    position in open_positions(game)
  end

  def open_positions(%__MODULE__{} = game) do
    taken = all_positions(game)

    0..(calc_num_positions(game.grid_size) - 1)
    |> Enum.filter(fn x -> x not in taken end)
  end

  def to_full_grid_for_ui(%__MODULE__{} = game) do
    game.sparse_grid
    |> Enum.with_index()
    |> Enum.map(fn {moves, index} ->
      moves
      |> Enum.reject(fn x -> x == @unplayed_position end)
      |> Enum.map(fn x -> {x, index} end)
    end)
    |> Enum.concat(
      game
      |> open_positions()
      |> Enum.map(fn x -> {x, @unplayed_position} end)
    )
    |> List.flatten()
    |> Enum.sort()
    |> Enum.map(fn {position, player} ->
      %Tictactemoji.GridCell{position: position, player: player}
    end)
    |> Enum.chunk_every(game.grid_size)
  end

  def rotate_player(player, _, _) when player < 0 do
    player
  end

  def rotate_player(player, num_players, rotations) when player < num_players do
    Integer.mod(player + rotations, num_players)
  end

  def to_nn_input_data(%__MODULE__{} = game) do
    {positions, oldest} =
      game.sparse_grid
      |> Enum.with_index()
      |> Enum.map(fn {positions, player} ->
        positions
        |> Enum.with_index()
        |> Enum.map(fn {x, index} -> {x, player, index == 0} end)
        |> Enum.reject(fn {x, _, _} -> x == @unplayed_position end)
      end)
      |> Enum.concat(
        game
        |> open_positions()
        |> Enum.map(fn x -> {x, @unplayed_position, false} end)
      )
      |> List.flatten()
      |> Enum.sort()
      |> Enum.reduce(
        {[], []},
        fn {_, player, move1}, {positions, oldest} ->
          {
            [rotate_player(player, game.num_players, game.current_player) + 1 | positions],
            [bool_to_int(move1) | oldest]
          }
        end
      )

    [
      rotate_player(game.current_player, game.num_players, game.current_player) + 1,
      Enum.reverse(positions),
      Enum.reverse(oldest)
    ]
  end

  defp bool_to_int(true), do: 1
  defp bool_to_int(false), do: 0

  defp all_positions(%__MODULE__{} = game) do
    game.sparse_grid
    |> List.flatten()
    |> Enum.reject(fn x -> x == @unplayed_position end)
    |> Enum.sort()
  end

  def current_player_oldest_position(%__MODULE__{} = game) do
    game.sparse_grid
    |> Enum.at(game.current_player)
    |> hd()
  end

  def set_current_player(%__MODULE__{} = game, player_index) do
    %{game | current_player: player_index}
  end

  def current_player_won?(%__MODULE__{} = game) do
    current_positions = Enum.at(game.sparse_grid, game.current_player)
    winning_moves?(current_positions, game.grid_size)
  end

  def winning_moves?(moves, grid_size) do
    moves = Enum.sort(moves)

    cond do
      List.first(moves) < 0 -> false
      List.last(moves) >= calc_num_positions(grid_size) -> false
      horizontal_winning_moves?(moves, grid_size) -> true
      vertical_winning_moves?(moves, grid_size) -> true
      diagonal_winning_moves?(moves, grid_size) -> true
      true -> false
    end
  end

  @doc ~S"""
  Checks if the given `moves` form a horizontal winning position.

  ## Examples

      iex> Tictactemoji.Game.horizontal_winning_moves?([0, 1, 2], 3)
      true

      iex> Tictactemoji.Game.horizontal_winning_moves?([2, 3, 4], 3)
      false

  """

  def horizontal_winning_moves?(moves, grid_size) do
    row_winner =
      moves
      |> calc_row_diffs(grid_size)
      |> Enum.all?(fn x -> x == 0 end)

    column_winner =
      moves
      |> calc_column_diffs(grid_size)
      |> Enum.all?(fn x -> x == 1 end)

    row_winner && column_winner
  end

  @doc ~S"""
  Checks if the given `moves` form a vertical winning position.

  ## Examples

      iex> Tictactemoji.Game.vertical_winning_moves?([1, 4, 7], 3)
      true

      iex> Tictactemoji.Game.vertical_winning_moves?([1, 4, 6], 3)
      false

  """

  def vertical_winning_moves?(moves, grid_size) do
    row_winner =
      moves
      |> calc_row_diffs(grid_size)
      |> Enum.all?(fn x -> x == 1 end)

    column_winner =
      moves
      |> calc_column_diffs(grid_size)
      |> Enum.all?(fn x -> x == 0 end)

    row_winner && column_winner
  end

  @doc ~S"""
  Checks if the given `moves` form a diagonal winning position.

  ## Examples

      iex> Tictactemoji.Game.diagonal_winning_moves?([1, 7, 13], 5)
      true

      iex> Tictactemoji.Game.diagonal_winning_moves?([3, 9, 15], 5)
      false

      iex> Tictactemoji.Game.diagonal_winning_moves?([2, 4, 6], 3)
      true

      iex> Tictactemoji.Game.diagonal_winning_moves?([0, 2, 4], 3)
      false

      iex> Tictactemoji.Game.diagonal_winning_moves?([1, 3, 5], 3)
      false

  """

  def diagonal_winning_moves?(moves, grid_size) do
    row_diffs = calc_row_diffs(moves, grid_size)
    column_diffs = calc_column_diffs(moves, grid_size)

    cond do
      Enum.any?(row_diffs, fn x -> x != 1 end) -> false
      Enum.all?(column_diffs, fn x -> x == 1 end) -> true
      Enum.all?(column_diffs, fn x -> x == -1 end) -> true
      true -> false
    end
  end

  # defp calc_diffs(moves) do
  #   tensor = Nx.tensor(moves)

  #   Nx.subtract(tensor[1..-1//1], tensor[0..-2//1])
  #   |> Nx.to_list()
  # end

  defp calc_diffs(moves) do
    [first | moves] = moves

    moves
    |> Enum.reduce({first, []}, fn x, {previous, diffs} ->
      {x, [x - previous | diffs]}
    end)
    |> elem(1)
  end

  def calc_row_diffs(moves, grid_size) do
    moves
    |> Enum.map(fn x -> calc_row_index(x, grid_size) end)
    |> calc_diffs()
  end

  def calc_row_index(position, grid_size) do
    div(position, grid_size)
  end

  def calc_column_diffs(moves, grid_size) do
    moves
    |> Enum.map(fn x -> calc_column_index(x, grid_size) end)
    |> calc_diffs()
  end

  def calc_column_index(position, grid_size) do
    rem(position, grid_size)
  end
end
