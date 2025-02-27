defmodule Tictactemoji.Model do
  alias Tictactemoji.TrainingData

  def new(num_players) do
    size = Integer.pow(num_players + 1, 2) * 4

    Axon.input("grid", shape: {nil, size})
    |> Axon.flatten()
    |> Axon.dense(512, activation: :relu6)
    |> Axon.dense(128, activation: :relu6)
    |> Axon.dense(9, activation: :softmax)
  end

  def train(model, training_data) do
    model
    |> Axon.Loop.trainer(
      :categorical_cross_entropy,
      Polaris.Optimizers.adam(learning_rate: 0.01)
    )
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(training_data, %{}, epochs: 55)
  end

  def predict(model, state, %Nx.Tensor{} = data) do
    model
    |> Axon.predict(state, data)
    |> Nx.to_flat_list()
    |> Enum.with_index()
    |> Enum.sort(:desc)
    |> IO.inspect(label: "PREDICTION")
    |> Enum.map(fn {_value, index} -> index end)
  end

  def predict(model, state, data) when is_list(data) do
    d =
      TrainingData.expand_positions_format(data)
      |> List.flatten()
      |> List.wrap()

    predict(model, state, Nx.tensor([d]))
  end
end
