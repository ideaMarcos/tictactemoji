defmodule Tictactemoji do
  @doc """
  Looks up `Application` config or raises if keyspace is not configured.

  ## Examples

      config :tictactemoji, :files, [
        uploads_dir: Path.expand("../priv/uploads", __DIR__),
        host: [scheme: "http", host: "localhost", port: 4000],
      ]

      iex> Tictactemoji.config([:files, :uploads_dir])
      iex> Tictactemoji.config([:files, :host, :port])
  """
  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:tictactemoji, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{inspect(keyspace)}"
      end
    end)
  end

  def mix_env, do: config([:mix_env])
end
