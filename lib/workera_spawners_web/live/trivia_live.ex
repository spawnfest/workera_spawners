defmodule WorkeraSpawnersWeb.TriviaLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div>
      <h1>Trivia Game</h1>
      <p>Question: <%= @question %></p>
      <p>Answer: <%= @answer %></p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, question: "What is the capital of France?", answer: "Paris")}
  end
end
