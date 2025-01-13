# Tictactemoji

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix


```
iex> {:ok, game} = Tictactemoji.Game.new("ABC123")
iex> {:ok, game} = Tictactemoji.Game.set_options(game, num_players: 3)
iex> {:ok, code, game} = Tictactemoji.Game.add_human_player(game)
iex> {:ok, game} = Tictactemoji.Game.add_cpu_players(game)
```

game = %Tictactemoji.Game{ id: "ABC123", grid_size: 3, num_players: 2, current_player: 1, player_tokens: ["N8GD6", "HQSRE"], player_emojis: [128056, 128053], sparse_grid: [[1, 3, 5], [0, 2, 4]], game_over?: false }

## Random

- `mix phx.new tictactemoji --no-ecto --no-mailer`
- `mix gettext.extract && mix gettext.merge priv/gettext`
