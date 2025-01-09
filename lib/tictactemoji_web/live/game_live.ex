defmodule TictactemojiWeb.GameLive do
  use TictactemojiWeb, :live_view

  require Logger
  alias Tictactemoji.Game
  alias Tictactemoji.GameServer
  alias Tictactemoji.Presence

  def mount(params, session, socket) do
    game_id = Map.get(params, "id")

    with %{"code" => player_code} <- session,
         {:ok, game} <- GameServer.get_game(game_id) do
      my_player_index =
        Enum.find_index(game.player_codes, fn x -> x == player_code end)

      my_emoji = Enum.at(game.player_emojis, my_player_index)

      Presence.track(self(), game_id, my_player_index, %{
        emoji: my_emoji
      })

      Presence.subscribe(game_id)

      presences =
        Presence.list(game_id)
        |> Presence.simple_presence_map()

      make_cpu_move(game, my_player_index)

      {:ok,
       socket
       |> assign(:game, game)
       |> assign(:my_player_index, my_player_index)
       |> assign(:my_player_code, player_code)
       |> assign(:my_emoji, my_emoji)
       |> assign(:presences, presences)}
    else
      _ -> {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("play_position", %{"position" => position}, socket) do
    {:ok, _} = GameServer.play_position(socket.assigns.game.id, String.to_integer(position))
    {:noreply, socket}
  end

  def handle_event("add_cpu_players", _params, socket) do
    :ok = GameServer.add_cpu_players(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_info(%{event: :player_added, payload: game}, socket) do
    my_player_index =
      Enum.find_index(game.player_codes, fn x -> x == socket.assigns.my_player_code end)

    IO.inspect(game, label: "player_added")
    make_cpu_move(game, my_player_index)

    {:noreply,
     socket
     |> update(:my_player_index, fn _ -> my_player_index end)
     |> update(:game, fn _ -> game end)}
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    IO.inspect(
      [
        payload_sparse_grid: game.sparse_grid,
        socket_sparse_grid: socket.assigns.game.sparse_grid
      ],
      label: "GAME_UPDATED"
    )

    make_cpu_move(game, socket.assigns.my_player_index)
    {:noreply, update(socket, :game, fn _ -> game end)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    # Presence.list(socket.assigns.game.id)
    # |> IO.inspect(label: "EVENT presence_diff")

    {:noreply, socket |> Presence.handle_diff(diff)}
  end

  def handle_info(:make_cpu_move, socket) do
    {:ok, _} = GameServer.make_cpu_move(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp format_cell(_, %Tictactemoji.GridCell{player: -1} = cell) do
    cell
  end

  defp format_cell(game, %Tictactemoji.GridCell{} = cell) do
    emoji = Enum.at(game.player_emojis, cell.player)
    %{cell | player: emoji}
  end

  defp make_cpu_move(game, current_player_index) do
    if Game.ready?(game) && Game.is_cpu_move?(game) &&
         Game.get_first_human_player_index(game) == current_player_index do
      Process.send_after(self(), :make_cpu_move, 2000)
    end
  end

  defp is_player_winner?(game, index) do
    game.game_over? && game.current_player == index
  end
end
