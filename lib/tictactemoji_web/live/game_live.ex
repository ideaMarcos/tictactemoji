defmodule TictactemojiWeb.GameLive do
  use TictactemojiWeb, :live_view

  require Logger
  alias Tictactemoji.Game
  alias Tictactemoji.GameServer
  alias Tictactemoji.Presence

  def mount(_params, session, socket) do
    with %{"token" => player_token, "game_id" => game_id} <- session,
         {:ok, game} <- GameServer.get_game(game_id) do
      my_player_index =
        Enum.find_index(game.player_tokens, fn x -> x == player_token end)

      my_emoji = Enum.at(game.player_emojis, my_player_index)

      presences =
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Tictactemoji.PubSub, game_id)

          Presence.track(self(), game_id, my_player_index, %{
            emoji: my_emoji
          })

          Presence.list(game_id)
          |> Presence.simple_presence_map()
        else
          []
        end

      {:ok,
       socket
       |> assign(:game, game)
       |> assign(:my_player_index, my_player_index)
       |> assign(:my_player_token, player_token)
       |> assign(:my_emoji, my_emoji)
       #  |> subscribe_to_game(game_id)}
       |> assign(:presences, presences)}
    else
      _ -> {:ok, redirect(socket, to: "/")}
    end
  end

  # defp subscribe_to_game(socket, game_id) do
  #   subscribed =
  #     if is_nil(socket.assigns.subscribed) && connected?(socket) do
  #       Phoenix.PubSub.subscribe(Tictactemoji.PubSub, game_id)
  #       |> to_string()
  #     else
  #       socket.assigns.subscribed
  #     end

  #   socket
  #   |> assign(:subscribed, subscribed)
  # end

  def handle_event("mark_position", %{"position" => position}, socket) do
    {:ok, _} = GameServer.mark_position(socket.assigns.game.id, position)
    {:noreply, socket}
  end

  def handle_event("reset_game", _params, socket) do
    {:ok, _} = GameServer.reset_game(socket.assigns.game.id)
    {:noreply, socket}
  end

  def handle_info(%{event: :player_added, payload: game}, socket) do
    my_player_index =
      Enum.find_index(game.player_tokens, fn x -> x == socket.assigns.my_player_token end)

    {:noreply,
     socket
     |> update(:my_player_index, fn _ -> my_player_index end)
     |> update(:game, fn _ -> game end)}
  end

  def handle_info(%{event: :game_updated, payload: game}, socket) do
    my_player_index =
      Enum.find_index(game.player_tokens, fn x -> x == socket.assigns.my_player_token end)

    {:noreply,
     socket
     |> update(:my_player_index, fn _ -> my_player_index end)
     |> update(:game, fn _ -> game end)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    # Presence.list(socket.assigns.game.id)
    # |> IO.inspect(label: "EVENT presence_diff")

    {:noreply, socket |> Presence.handle_diff(diff)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp player_emoji(%Game{} = game, index) do
    Enum.at(game.player_emojis, index)
  end

  defp format_cell(_, %Tictactemoji.GridCell{player: -1} = cell) do
    cell
  end

  defp format_cell(%Game{} = game, %Tictactemoji.GridCell{} = cell) do
    emoji = player_emoji(game, cell.player)
    %{cell | player: emoji}
  end

  defp is_player_winner?(%Game{} = game, index) do
    game.result == :win && game.current_player == index
  end

  defp is_tie_game?(%Game{} = game) do
    game.result == :tie
  end

  defp last_played_position_class(%Game{} = game, position) do
    game.sparse_grid
    |> Enum.flat_map(fn row -> [List.first(row)] end)
    |> Enum.any?(fn x -> x == position end)
    |> case do
      true -> "underline"
      false -> ""
    end
  end

  defp mark_position(position) do
    JS.push("mark_position", value: %{position: position})
    # |> JS.transition("animate-wiggle", to: "#cell#{position}", time: 5000)
  end

  defp rematch(num_players) do
    event =
      JS.push("reset_game")

    Enum.reduce(0..(num_players - 1), event, fn index, event ->
      event
      |> JS.transition("animate-spin", to: "#emoji#{index}", time: 1000)
    end)
  end
end
