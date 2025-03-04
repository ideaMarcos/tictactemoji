# Tictactemoji

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


https://github.com/user-attachments/assets/75bef452-8ed9-4f34-9689-cfc1b22a5a69


## Tech Notes

* Wanted to learn more about [https://github.com/elixir-nx](Nx)
* Used variation of tic tac toe where only last 3 moves are kept
* Created neural network with Axon. Uses supervised learning.
* Meant to run locally. Not deploying this anywhere.
* The training data included is not explained. Maybe later. It's a lot to write.
* The grid is represented as a list from 0-8
```
0 | 1 | 2
3 | 4 | 5
6 | 7 | 8
```
* Each potential move is scored. The output on the console looks like:
```
PREDICTION: [
  {0.9915338158607483, 3},
  {0.003853111295029521, 6},
  {0.001458177575841546, 5},
  {9.841511491686106e-4, 2},
  {9.607021347619593e-4, 7},
  {9.043502504937351e-4, 8},
  {2.5609220028854907e-4, 4},
  {2.5914539946825244e-5, 1},
  {2.355606557102874e-5, 0}
```


## Helpful resources

* https://pragprog.com/titles/smelixir/machine-learning-in-elixir/
* https://introtodeeplearning.com
* https://www.youtube.com/playlist?list=PLbdTl8vSSyUDWtx6ZRnfzU3jo0Kpd9CxX
* https://the-mvm.github.io/deep-q-learning-tic-tac-toe.html

