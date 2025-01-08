defmodule Tictactemoji.GameServer do
  require Logger
  use GenServer

  alias Tictactemoji.Game

  def get_game(pid) when is_pid(pid) do
    GenServer.call(pid, :get_game)
  end

  def get_game(game_id) do
    call_by_name(game_id, :get_game)
  end

  def add_player(game_id) do
    with {:ok, code, game} <- call_by_name(game_id, :add_player),
         :ok <- broadcast_player_added!(game_id, game) do
      {:ok, code}
    end
  end

  def set_options(game_id, options) do
    with {:ok, game} <- call_by_name(game_id, {:set_options, options}),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, game}
    end
  end

  def play_position(game_id, position) do
    with {:ok, game} <- call_by_name(game_id, {:play_position, position}),
         :ok <- broadcast_game_updated!(game_id, game) do
      {:ok, game}
    end
  end

  def start_link(game_id) do
    GenServer.start(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def game_pid(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  @impl GenServer
  def init(game_id) do
    Logger.info("Creating game server for #{game_id}")
    {:ok, game} = Game.new(game_id)
    {:ok, %{game: game}}
  end

  @impl GenServer
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call(:add_player, _from, state) do
    case Game.add_player(state.game) do
      {:ok, code, game} ->
        {:reply, {:ok, code, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:set_options, options}, _from, state) do
    case Game.set_options(state.game, options) do
      {:ok, game} ->
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:play_position, position}, _from, state) do
    case Game.play_position(state.game, position) do
      {:ok, game} ->
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @spec broadcast!(String.t(), atom(), map()) :: :ok
  def broadcast!(game_id, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Tictactemoji.PubSub, game_id, %{event: event, payload: payload})
  end

  defp call_by_name(game_id, command) do
    case game_pid(game_id) do
      game_pid when is_pid(game_pid) ->
        GenServer.call(game_pid, command)

      nil ->
        {:error, :game_not_found}
    end
  end

  # defp cast_by_name(game_id, command) do
  #   case game_pid(game_id) do
  #     game_pid when is_pid(game_pid) ->
  #       GenServer.cast(game_pid, command)

  #     nil ->
  #       {:error, :game_not_found}
  #   end
  # end

  defp broadcast_player_added!(game_id, game) do
    broadcast!(to_string(game_id), :player_added, game)
  end

  defp broadcast_game_updated!(game_id, game) do
    broadcast!(to_string(game_id), :game_updated, game)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Tictactemoji.GameRegistry, game_id}}
  end
end
