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

      {:ok,
       socket
       |> assign(:game, game)
       |> assign(:my_player_index, my_player_index)
       |> assign(:my_emoji, my_emoji)
       |> assign(:presences, presences)}
    else
      _ -> {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("play_position", %{"position" => position}, socket) do
    GameServer.play_position(socket.assigns.game.id, String.to_integer(position))
    |> case do
      {:ok, game} -> {:noreply, update(socket, :game, fn _ -> game end)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(%{event: :player_added, payload: game}, socket) do
    my_player_index =
      Enum.find_index(game.player_codes, fn x -> x == socket.assigns.my_player_code end)

    {:noreply,
     socket
     |> update(:my_player_index, fn _ -> my_player_index end)
     |> update(:game, fn _ -> game end)}
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    {:noreply, update(socket, :game, fn _ -> game end)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    # Presence.list(socket.assigns.game.id)
    # |> IO.inspect(label: "EVENT presence_diff")

    {:noreply, socket |> Presence.handle_diff(diff)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp format_cell(_, %Tictactemoji.GridCell{player: -1} = cell) do
    # %{cell | player: 10067}
    cell
  end

  defp format_cell(game, %Tictactemoji.GridCell{} = cell) do
    emoji = Enum.at(game.player_emojis, cell.player)
    %{cell | player: emoji}
  end

  attr :cell, :map

  defp taken_cell(assigns) do
    ~H"""
    <span>&#{@cell.player};</span>
    """
  end

  attr :position, :integer

  defp playable_cell(assigns) do
    ~H"""
    <a href="#" phx-click="play_position" phx-value-position={@position}>❓</a>
    """
  end
end
