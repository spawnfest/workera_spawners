defmodule WorkeraSpawners.GameServer.QuestionRepo do
  alias WorkeraSpawners.GameServer.Question

  @questions [
    %Question{text: "What is the capital of Peru?", answer: "Lima"},
    %Question{text: "What is the capital of Canada?", answer: "Ottawa"},
    %Question{text: "What is the capital of Austria?", answer: "Vienna"}
  ]

  def get_random_question() do
    Nx.default_backend(EXLA.Backend)

    {:ok, model} = Bumblebee.load_model({:hf, "google/flan-t5-xl"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "google/flan-t5-xl"})

    {:ok, generation_config} =
      Bumblebee.load_generation_config({:hf, "google/flan-t5-xl"})

    serving =
      Bumblebee.Text.generation(model, tokenizer, generation_config,
        defn_options: [compiler: EXLA]
      )

    %{results: [%{text: question}]} =
      Nx.Serving.run(
        serving,
        "Generate a trivia question which can be answered in one word"
      )

    %{results: [%{text: answer}]} =
      Nx.Serving.run(
        serving,
        "What is the one-word answer to the question \"#{question}\"?"
      )

    %Question{text: question, answer: answer, asked_at: Timex.now()}
  end
end
