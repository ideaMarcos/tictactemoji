defmodule TictactemojiWeb.HomeLive do
  use TictactemojiWeb, :live_view

  alias Tictactemoji.Game
  alias Tictactemoji.GameServer
  alias Tictactemoji.GameSupervisor
  alias Tictactemoji.Schema.GameOptions

  def mount(_params, _session, socket) do
    changeset =
      GameOptions.new()
      |> GameOptions.changeset(%{})

    {:ok, assign(socket, form: to_form(changeset))}
  end

  def handle_event("create_game", %{"game_options" => params}, socket) do
    GameOptions.new()
    |> GameOptions.changeset(params)
    |> GameOptions.apply_update_action()
    |> case do
      {:ok, game_options} ->
        start_game(socket, game_options)

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp start_game(socket, game_options) do
    game_id = Game.new_game_id()

    with {:ok, _} <- GameSupervisor.start_game(game_id),
         {:ok, _} <- GameServer.set_options(game_id, num_players: game_options.num_players) do
      {:noreply, redirect(socket, to: "/game/join/#{game_id}")}
    end
  end
end
