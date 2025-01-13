defmodule Tictactemoji.Presence do
  use Phoenix.Presence, otp_app: :tictactemoji, pubsub_server: Tictactemoji.PubSub

  def fetch(_game_id, presences) do
    # TODO if there was db, then get players from db
    # {:ok, game} = Tictactemoji.GameServer.get_game(game_id)
    # Enum.zip(game.player_tokens, game.player_names)
    # |> Enum.into(%{})

    # for {key, %{metas: metas}} <- presences, into: %{} do
    #   {key, %{metas: metas, user: users[String.to_integer(key)]}}
    # end

    presences
  end

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {topic, %{metas: [meta | _]}} ->
      {topic, meta}
    end)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))
    Phoenix.Component.assign(socket, presences: presences)
  end

  defp remove_presences(socket, leaves) do
    topics = Enum.map(leaves, fn {topic, _} -> topic end)
    presences = Map.drop(socket.assigns.presences, topics)
    Phoenix.Component.assign(socket, presences: presences)
  end

  def handle_diff(socket, presence_diff) do
    socket
    |> remove_presences(presence_diff.leaves)
    |> add_presences(presence_diff.joins)
  end
end
