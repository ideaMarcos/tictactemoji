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
  ###  0 |  1
  ###  2 |  3

  @not_played_position -1

  defstruct id: nil,
            grid_size: nil,
            num_players: nil,
            current_player: nil,
            player_codes: nil,
            player_emojis: nil,
            sparse_grid: nil,
            game_over?: nil

  def new(game_id) do
    game = %__MODULE__{
      id: game_id,
      player_codes: [],
      player_emojis: [],
      game_over?: false
    }

    {:ok, game}
  end

  def new_game_id do
    Enum.take_random(~c/ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/, 9)
    |> to_string()
  end

  def set_options(%__MODULE__{} = game, options) when is_list(options) do
    if game.player_codes == [] do
      do_set_options(game, options)
    else
      {:error, :game_already_started}
    end
  end

  defp do_set_options(%__MODULE__{} = game, options) do
    num_players = Keyword.get(options, :num_players, 1)
    grid_size = max(num_players + 1, 3)

    {:ok,
     %{
       game
       | grid_size: grid_size,
         num_players: num_players,
         sparse_grid:
           List.duplicate(@not_played_position, grid_size) |> List.duplicate(num_players)
     }}
  end

  defp start_game_if_ready(%__MODULE__{id: id} = game) do
    if ready?(game) do
      Logger.info("starting new game", id: id)

      %{
        game
        | current_player: Enum.random(0..(game.num_players - 1)),
          player_emojis: Enum.take_random(~c"🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯", game.num_players)
      }
    else
      game
    end
  end

  def ready?(%__MODULE__{} = game) do
    length(game.player_codes) == game.num_players
  end

  def add_player(%__MODULE__{} = game) do
    if length(game.player_codes) >= game.num_players do
      {:error, :too_many_players}
    else
      code =
        Enum.take_random(~c/ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/, 5)
        |> to_string()

      {:ok, code,
       %{game | player_codes: [code | game.player_codes]}
       |> start_game_if_ready()}
    end
  end

  def play_position(%__MODULE__{game_over?: true}, _), do: {:error, :game_over}

  def play_position(%__MODULE__{} = game, position) do
    if game.game_over? do
      {:error, :game_over}
    else
      if playable_position?(game, position) do
        current_positions = Enum.at(game.sparse_grid, game.current_player)
        [_oldest | new_current_positions] = Enum.concat(current_positions, [position])

        new_sparse_grid =
          List.replace_at(game.sparse_grid, game.current_player, new_current_positions)

        game = %{game | sparse_grid: new_sparse_grid}
        player_won = current_player_won?(game)

        current_player =
          if player_won do
            game.current_player
          else
            rem(game.current_player + 1, game.num_players)
          end

        {:ok, %{game | current_player: current_player, game_over?: player_won}}
      else
        {:error, :position_already_taken}
      end
    end
  end

  def playable_position?(%__MODULE__{} = game, position) do
    position in playable_positions(game)
  end

  def playable_positions(%__MODULE__{} = game) do
    taken = all_positions(game)

    0..(Integer.pow(game.grid_size, 2) - 1)
    |> Enum.filter(fn x -> x not in taken end)
  end

  def to_full_grid(%__MODULE__{} = game) do
    game.sparse_grid
    |> Enum.with_index()
    |> Enum.map(fn {moves, index} ->
      moves
      |> remove_unplayed_positions()
      |> Enum.map(fn x -> {x, index} end)
    end)
    |> Enum.concat(
      game
      |> playable_positions()
      |> Enum.map(fn x -> {x, @not_played_position} end)
    )
    |> List.flatten()
    |> Enum.sort()
    |> Enum.map(fn {position, player} ->
      %Tictactemoji.GridCell{position: position, player: player}
    end)
    |> Enum.chunk_every(game.grid_size)
  end

  defp all_positions(%__MODULE__{} = game) do
    game.sparse_grid
    |> List.flatten()
    |> remove_unplayed_positions()
    |> Enum.sort()
  end

  defp remove_unplayed_positions(positions) do
    positions
    |> Enum.reject(fn x -> x == @not_played_position end)
  end

  def current_player_oldest_position(%__MODULE__{} = game) do
    game.sparse_grid
    |> Enum.at(game.current_player)
    |> hd()
  end

  def current_player_won?(%__MODULE__{} = game) do
    current_positions = Enum.at(game.sparse_grid, game.current_player)
    winning_moves?(current_positions, game.grid_size)
  end

  defp winning_moves?(moves, grid_size) do
    moves = Enum.sort(moves)

    cond do
      Enum.all?(moves, fn x -> x < 0 || x >= grid_size end) -> false
      horizontal_winning_moves?(moves, grid_size) -> true
      vertical_winning_moves?(moves, grid_size) -> true
      main_diagonal_winning_moves?(moves, grid_size) -> true
      anti_diagonal_winning_moves?(moves, grid_size) -> true
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
    is_left_column = rem(hd(moves), grid_size) == 0

    if is_left_column do
      moves
      |> calc_diffs()
      |> Enum.all?(fn x -> x == 1 end)
    else
      false
    end
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
    moves
    |> calc_diffs()
    |> Enum.all?(fn x -> x == grid_size end)
  end

  @doc ~S"""
  Checks if the given `moves` form a vertical winning position.

  ## Examples

      iex> Tictactemoji.Game.main_diagonal_winning_moves?([0, 4, 8], 3)
      true

      iex> Tictactemoji.Game.main_diagonal_winning_moves?([4, 8, 12], 3)
      false

  """

  def main_diagonal_winning_moves?([0 | _] = moves, grid_size) do
    diffs = calc_diffs(moves)

    Enum.all?(diffs, fn x -> x == grid_size + 1 end)
  end

  def main_diagonal_winning_moves?(_, _) do
    false
  end

  @doc ~S"""
  Checks if the given `moves` form a vertical winning position.

  ## Examples

      iex> Tictactemoji.Game.anti_diagonal_winning_moves?([2, 4, 6], 3)
      true

      iex> Tictactemoji.Game.anti_diagonal_winning_moves?([0, 2, 4], 3)
      false

  """

  def anti_diagonal_winning_moves?([0, _], _) do
    false
  end

  def anti_diagonal_winning_moves?(moves, grid_size) do
    diffs = calc_diffs(moves)

    List.first(moves) != 0 &&
      Enum.all?(diffs, fn x -> x == grid_size - 1 end)
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
end
