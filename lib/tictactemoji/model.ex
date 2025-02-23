defmodule Tictactemoji.Model do
  def new(num_players) do
    size = num_players * num_players * 2 + 1

    Axon.input("grid", shape: {nil, size})
    |> Axon.flatten()
    |> Axon.dense(128, activation: :relu)
    |> Axon.dense(9, activation: :softmax)
  end

  def train(model, training_data) do
    model
    |> Axon.Loop.trainer(
      :categorical_cross_entropy,
      Polaris.Optimizers.adam(learning_rate: 0.01)
    )
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    # |> Axon.Loop.trainer(
    #   :mean_squared_error,
    #   :sgd
    # )
    # |> Axon.Loop.metric(:mean_absolute_error)
    |> Axon.Loop.run(training_data, %{}, epochs: 50)
  end

  def predict(model, state, %Nx.Tensor{} = data) do
    model
    |> Axon.predict(state, data)
    # |> Nx.argmax()
    # |> Nx.to_number()
    |> Nx.to_flat_list()
    |> Enum.with_index()
    |> Enum.sort(:desc)
    |> IO.inspect(label: "PREDICTION: ")
    |> Enum.map(fn {_value, index} -> index end)
  end

  def predict(model, state, data) when is_list(data) do
    predict(model, state, Nx.tensor([List.flatten(data)], type: :s8))
  end
end
