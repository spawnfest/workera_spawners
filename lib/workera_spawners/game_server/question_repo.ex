defmodule WorkeraSpawners.GameServer.QuestionRepo do
  alias WorkeraSpawners.GameServer.Question

  @questions [
    %Question{text: "What is the capital of Peru?", answer: "Lima"},
    %Question{text: "What is the capital of Canada?", answer: "Ottawa"},
    %Question{text: "What is the capital of Austria?", answer: "Vienna"}
  ]

  def get_random_question() do
    Nx.default_backend(EXLA.Backend)

    {:ok, model} = Bumblebee.load_model({:hf, "OpenAssistant/oasst-sft-1-pythia-12b"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "OpenAssistant/oasst-sft-1-pythia-12b"})
    serving = Bumblebee.Text.generation(model, tokenizer, defn_options: [compiler: EXLA])

    question =
      Nx.Serving.run(
        serving,
        "<|prompter|>Generate a trivia question which can be answered in one word.<|endoftext|><|assistant|>"
      )

    answer =
      Nx.Serving.run(
        serving,
        "<|prompter|>What is the one-word answer to the question \"#{question}\"?<|endoftext|><|assistant|>"
      )

    %Question{text: question, answer: answer, asked_at: Timex.now()}
  end
end
