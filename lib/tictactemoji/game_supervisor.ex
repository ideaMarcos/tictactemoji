defmodule Tictactemoji.GameSupervisor do
  use DynamicSupervisor

  alias Tictactemoji.GameServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def which_children do
    Supervisor.which_children(__MODULE__)
  end

  def start_game(game_id) do
    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [game_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game(game_id) do
    case GameServer.game_pid(game_id) do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      nil ->
        :ok
    end
  end
end
