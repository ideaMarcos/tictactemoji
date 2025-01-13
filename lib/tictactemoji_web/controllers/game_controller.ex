defmodule TictactemojiWeb.GameController do
  use TictactemojiWeb, :controller

  alias Tictactemoji.GameServer

  def join(conn, %{"id" => game_id} = _params) do
    if game_exists?(game_id) do
      case GameServer.add_human_player(game_id) do
        {:ok, token} ->
          conn
          |> put_session(:token, token)
          |> put_session(:game_id, game_id)
          |> redirect(to: "/game/play")

        {:error, :too_many_players} ->
          conn
          |> redirect(to: "/game/busy")
      end
    else
      conn
      |> delete_session(:token)
      |> delete_session(:game_id)
      |> redirect(to: "/")
    end
  end

  defp game_exists?(game_id) do
    with {:ok, game} <- GameServer.get_game(game_id) do
      !game.game_over?
    else
      _ -> false
    end
  end
end
