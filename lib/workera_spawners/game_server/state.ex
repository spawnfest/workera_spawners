defmodule WorkeraSpawners.GameServer.State do
  @default_answer_time 30 * 1000
  @default_question_amount 3
  defstruct game_state: :undefined,
            answer_time: @default_answer_time,
            question_amount: @default_question_amount,
            players: [],
            questions: []
end
