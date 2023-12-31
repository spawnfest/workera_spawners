defmodule WorkeraSpawners.GameServer.QuestionRepo do
  alias WorkeraSpawners.GameServer.Question

  @questions [
    %Question{text: "What is the capital of Peru?", answer: "Lima"},
    %Question{text: "What is the capital of Canada?", answer: "Ottawa"},
    %Question{text: "What is the capital of Austria?", answer: "Vienna"}
  ]

  def get_random_question() do
    @questions
    |> Enum.random()
    |> Map.put(:asked_at, Timex.now())
  end
end
