defmodule WorkeraSpawners.GameServer.State do
  @default_answer_time 30 * 1000
  defstruct game_state: :undefined, answer_time: @default_answer_time, players: [], question: nil
end
