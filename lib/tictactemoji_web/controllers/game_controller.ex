defmodule TictactemojiWeb.GameController do
  use TictactemojiWeb, :controller

  alias Tictactemoji.GameServer

  def join(conn, %{"id" => game_id} = _params) do
    case GameServer.add_human_player(game_id) do
      {:ok, code} ->
        conn
        |> put_session(:code, code)
        |> redirect(to: "/game/play/#{game_id}")

      {:error, :too_many_players} ->
        conn
        |> redirect(to: "/game/busy")
    end
  end
end
