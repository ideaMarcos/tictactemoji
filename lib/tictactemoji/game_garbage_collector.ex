defmodule Tictactemoji.GameGarbageCollector do
  use GenServer

  alias Tictactemoji.GameServer
  alias Tictactemoji.GameSupervisor

  require Logger

  @job_interval :timer.minutes(2)

  def start_link(_) do
    GenServer.start(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init(state) do
    {:noreply, state} = handle_info(:work, state)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:work, state) do
    work(state)
    schedule_work()
    {:noreply, state}
  end

  defp work(_state) do
    Logger.info("Looking for games to stop")

    GameSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      {:ok, game} = GameServer.get_game(pid)

      if game.game_over? do
        Logger.info("Stopping game #{game.id}")
        GameSupervisor.stop_game(game.id)
      end
    end)
  end

  defp schedule_work(),
    do: Process.send_after(self(), :work, @job_interval)
end
