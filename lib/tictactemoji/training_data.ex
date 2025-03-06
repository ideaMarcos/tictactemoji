defmodule Tictactemoji.TrainingData do
  require Logger
  alias Tictactemoji.Game

  def to_tensor(game_data, num_players) when is_list(game_data) do
    num_positions =
      num_players |> Game.calc_grid_size() |> Game.calc_num_positions()

    best_move_variations = best_move_variations()

    {game_state_data, best_move_data} =
      game_data
      |> Enum.flat_map(fn x -> add_variations(x, best_move_variations) end)
      |> List.flatten()
      |> Enum.map(&to_one_hot_encoding/1)
      |> Enum.shuffle()
      |> Enum.reduce(
        {[], []},
        fn {next_state, next_move}, {game_states, best_moves} ->
          {
            [List.flatten(next_state) | game_states],
            [next_move | best_moves]
          }
        end
      )

    game_states =
      game_state_data
      |> Nx.tensor()

    best_moves =
      best_move_data
      |> Nx.tensor()
      |> Nx.new_axis(-1)
      |> Nx.equal(Nx.iota({1, num_positions}))

    train_count = length(game_state_data)
    Logger.info(train_count: train_count)

    train_range = 0..(train_count - 1)//1

    train_game_states = game_states[train_range]
    train_best_moves = best_moves[train_range]

    train_batch_size = min(train_count, 256)

    train_game_states
    |> Nx.to_batched(train_batch_size)
    |> Stream.zip(Nx.to_batched(train_best_moves, train_batch_size))
  end

  def best_move_variations() do
    Nx.tensor([[0, 1, 2], [3, 4, 5], [6, 7, 8]])
    |> compute_rotations()
    |> Enum.map(&Nx.to_flat_list/1)
  end

  def to_one_hot_encoding({[positions, oldest], best_move}) do
    {to_one_hot_encoding([positions, oldest]), best_move}
  end

  def to_one_hot_encoding([positions, oldest]) do
    Enum.zip(positions, oldest)
    |> Enum.map(fn {p, o} ->
      cond do
        o == 1 -> [1, 0, 0, 0]
        p == 0 -> [0, 1, 0, 0]
        p == 1 -> [0, 0, 1, 0]
        p == 2 -> [0, 0, 0, 1]
      end
    end)
  end

  def add_variations({[positions, oldest], best_move}, best_move_variations) do
    position_variations =
      Nx.tensor(positions) |> Nx.reshape({3, 3}) |> compute_rotations()

    oldest_variations =
      Nx.tensor(oldest) |> Nx.reshape({3, 3}) |> compute_rotations()

    Enum.zip(position_variations, oldest_variations)
    |> Enum.with_index()
    |> Enum.map(fn {{p, o}, idx} ->
      flat_o = Nx.to_flat_list(o)
      flat_p = Nx.to_flat_list(p)

      {[flat_p, flat_o],
       best_move_variations |> Enum.at(idx) |> Enum.find_index(fn x -> x == best_move end)}
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def compute_rotations(%Nx.Tensor{} = t) do
    [
      t,
      t |> rot90(),
      t |> flipud() |> fliplr(),
      t |> flipud() |> rot90() |> flipud(),
      t |> fliplr(),
      t |> fliplr() |> rot90(),
      t |> flipud(),
      t |> fliplr() |> flipud() |> rot90() |> flipud()
    ]
  end

  # from numpy
  defp rot90(%Nx.Tensor{} = t), do: t |> Nx.transpose() |> Nx.reverse(axes: [1])
  defp fliplr(%Nx.Tensor{} = t), do: t |> Nx.reverse(axes: [1])
  defp flipud(%Nx.Tensor{} = t), do: t |> Nx.reverse(axes: [0])

  def print_ascii_art({[positions, old_moves], best_move} = data, grid_size \\ 3) do
    chunky_positions =
      Enum.zip(positions, old_moves)
      |> Enum.with_index()
      |> Enum.map(fn {{p, om}, idx} ->
        cond do
          idx == best_move -> " X "
          p == 0 -> " - "
          om == 1 -> "'#{p}'"
          true -> " #{p} "
        end
      end)
      |> Enum.chunk_every(grid_size)

    Enum.join(
      [
        # "-- #{Enum.count(positions, fn x -> x != 0 end)} positions played",
        inspect(data)
        | chunky_positions
      ],
      "\n"
    )
    |> IO.puts()
  end

  def path do
    Path.join(Application.app_dir(:tictactemoji, "priv"), "training.dat")
  end

  def save(data) do
    path()
    |> File.write!(:erlang.term_to_binary(data))
  end

  def load() do
    path()
    |> File.read()
    |> case do
      {:ok, data} ->
        :erlang.binary_to_term(data)

      {:error, _} ->
        Logger.error("No training data found. Run `mix train` to generate it.")
        []
    end
  end

  def data_for_move(1) do
    [
      {[[0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 4}
    ]
  end

  def data_for_move(2) do
    [
      {[[0, 0, 0, 0, 0, 0, 0, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 4},
      {[[0, 0, 0, 0, 0, 0, 0, 2, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 4},
      {[[0, 0, 0, 0, 2, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1}
    ]
  end

  def data_for_move(3) do
    [
      {[[0, 0, 0, 0, 1, 0, 0, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 5},
      {[[0, 0, 0, 0, 1, 0, 0, 2, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 6}
    ]
  end

  def data_for_move(4) do
    [
      {[[0, 0, 0, 0, 1, 0, 0, 2, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 6},
      {[[0, 0, 0, 0, 1, 0, 2, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 7},
      {[[0, 0, 0, 0, 2, 0, 0, 1, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 0},
      {[[0, 0, 0, 0, 2, 0, 0, 2, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1},
      {[[0, 0, 0, 0, 2, 0, 1, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 0},
      {[[0, 0, 0, 0, 2, 1, 0, 2, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1},
      {[[0, 0, 0, 0, 2, 1, 2, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 2},
      {[[0, 0, 1, 0, 2, 0, 2, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1}
    ]
  end

  def data_for_move(5) do
    [
      {[[0, 0, 0, 0, 1, 0, 1, 2, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 2},
      {[[0, 0, 0, 0, 1, 0, 2, 1, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1},
      {[[0, 0, 0, 0, 1, 1, 0, 2, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 3},
      {[[0, 0, 0, 0, 1, 1, 2, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 3},
      {[[0, 0, 0, 0, 1, 2, 1, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 2},
      {[[0, 0, 0, 0, 1, 2, 2, 0, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 0},
      {[[0, 0, 0, 0, 1, 2, 2, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1},
      {[[0, 0, 0, 1, 1, 2, 2, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 7},
      {[[0, 0, 0, 2, 1, 2, 0, 0, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 0},
      {[[0, 0, 1, 0, 1, 0, 2, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 7},
      {[[0, 0, 1, 0, 1, 2, 2, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1},
      {[[0, 0, 1, 2, 1, 0, 0, 0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 6},
      {[[0, 0, 2, 0, 1, 0, 2, 0, 1], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 0},
      {[[0, 0, 2, 0, 1, 0, 2, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]], 1}
    ]
  end

  def data_for_move(6) do
    [
      {[[0, 0, 0, 1, 1, 2, 2, 1, 2], [0, 0, 0, 0, 1, 0, 1, 0, 0]], 2},
      {[[0, 0, 0, 1, 2, 2, 0, 1, 2], [0, 0, 0, 0, 1, 0, 0, 0, 0]], 2},
      {[[0, 0, 1, 0, 1, 2, 2, 0, 2], [0, 0, 0, 0, 0, 1, 0, 0, 0]], 7},
      {[[0, 0, 1, 0, 2, 1, 2, 0, 2], [0, 0, 0, 0, 1, 0, 0, 0, 0]], 7},
      {[[0, 0, 1, 1, 2, 0, 2, 2, 1], [0, 0, 1, 0, 0, 0, 1, 0, 0]], 1},
      {[[0, 0, 1, 1, 2, 2, 0, 1, 2], [0, 0, 0, 1, 0, 1, 0, 0, 0]], 0},
      {[[0, 0, 1, 2, 1, 2, 2, 1, 0], [0, 0, 0, 0, 1, 1, 0, 0, 0]], 0},
      {[[0, 0, 1, 2, 2, 0, 2, 1, 1], [0, 0, 1, 0, 0, 0, 1, 0, 0]], 5},
      {[[0, 0, 1, 2, 2, 1, 1, 2, 0], [0, 0, 0, 0, 0, 1, 0, 1, 0]], 5},
      {[[0, 0, 1, 2, 2, 1, 1, 2, 0], [0, 0, 0, 1, 0, 1, 0, 0, 0]], 1},
      {[[0, 0, 1, 2, 2, 1, 1, 2, 0], [0, 0, 1, 1, 0, 0, 0, 0, 0]], 1},
      {[[0, 1, 2, 2, 1, 0, 1, 0, 2], [0, 0, 0, 1, 1, 0, 0, 0, 0]], 5},
      {[[1, 0, 2, 0, 1, 0, 2, 1, 2], [0, 0, 0, 0, 1, 0, 1, 0, 0]], 5}
    ]
  end

  def data_for_move(num_players) do
    raise "No data for #{num_players} players"
  end
end
