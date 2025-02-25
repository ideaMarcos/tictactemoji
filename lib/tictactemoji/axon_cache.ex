defmodule Tictactemoji.AxonCache do
  use Agent

  alias Tictactemoji.Model
  alias Tictactemoji.TrainingData

  def start_link(_) do
    data = TrainingData.load()
    group1_state = train_model([1, 2, 3])
    group2_state = train_model([4])
    group3_state = train_model([5])
    group4_state = train_model([6], data)

    states = %{
      group1_state: group1_state,
      group2_state: group2_state,
      group3_state: group3_state,
      group4_state: group4_state
    }

    Agent.start_link(fn -> states end, name: __MODULE__)
  end

  def train_model(group_moves, extra_moves \\ []) do
    num_players = 2
    model = Model.new(num_players)

    train_data =
      group_moves
      |> Enum.map(fn move -> TrainingData.data_for_move(move) end)
      |> Enum.concat()
      |> Enum.concat(extra_moves)
      |> TrainingData.to_tensor(num_players)

    Model.train(model, train_data)
  end

  def get_state(move) when move <= 3 do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:group1_state)
  end

  def get_state(move) when move == 4 do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:group2_state)
  end

  def get_state(move) when move == 5 do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:group3_state)
  end

  def get_state(move) when move >= 6 do
    Agent.get(__MODULE__, & &1)
    |> Map.get(:group4_state)
  end
end
