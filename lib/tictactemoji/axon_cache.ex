defmodule Tictactemoji.AxonCache do
  use Agent

  alias Tictactemoji.Model
  alias Tictactemoji.TrainingData

  def start_link(_) do
    model_state = train_model()
    Agent.start_link(fn -> model_state end, name: __MODULE__)
  end

  def train_model() do
    num_players = 2
    model = Model.new(num_players)

    train_data =
      1..6
      |> Enum.map(fn move -> TrainingData.data_for_move(move) end)
      |> Enum.concat()
      |> Enum.concat(TrainingData.load())
      |> TrainingData.to_tensor(num_players)

    Model.train(model, train_data)
  end

  def get_state(_) do
    Agent.get(__MODULE__, & &1)
  end
end
