defmodule Tictactemoji.AxonCache do
  use Agent

  alias Tictactemoji.Model
  alias Tictactemoji.TrainingData

  def start_link(_) do
    group1_state = train_model([1, 2])
    group2_state = train_model([3, 4])
    group3_state = train_model([5])
    group4_state = train_model([6])

    states = %{
      group1_state: group1_state,
      group2_state: group2_state,
      group3_state: group3_state,
      group4_state: group4_state
    }

    Agent.start_link(fn -> states end, name: __MODULE__)
  end

  def train_model(moves) do
    num_players = 2
    model = Model.new(num_players)

    train_data =
      moves
      |> Enum.map(fn move -> TrainingData.data_for_move(move) end)
      |> Enum.concat()
      |> TrainingData.to_tensor(num_players)

    Model.train(model, train_data)
  end

  def get_state(move) when move <= 2 do
    IO.inspect(get_state: "group1_state")

    Agent.get(__MODULE__, & &1)
    |> Map.get(:group1_state)
  end

  def get_state(move) when move in [3, 4] do
    IO.inspect(get_state: "group2_state")

    Agent.get(__MODULE__, & &1)
    |> Map.get(:group2_state)
  end

  def get_state(move) when move in [5] do
    IO.inspect(get_state: "group3_state")

    Agent.get(__MODULE__, & &1)
    |> Map.get(:group3_state)
  end

  def get_state(move) when move in [6] do
    IO.inspect(get_state: "group4_state")

    Agent.get(__MODULE__, & &1)
    |> Map.get(:group4_state)
  end

  def get_state(move) when move > 6 do
    IO.inspect(get_state: "group5_state")

    Agent.get(__MODULE__, & &1)
    |> Map.get(:group4_state)
  end
end
