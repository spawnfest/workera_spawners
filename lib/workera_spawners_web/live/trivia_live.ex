defmodule WorkeraSpawnersWeb.TriviaLive do
  use WorkeraSpawnersWeb, :live_view

  alias WorkeraSpawners.GameServer

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
      game_state: :awaiting_name,
      name: nil,
      question: nil
      )
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <%= case @game_state do %>
        <% :awaiting_name -> %>
          <%= form_for :name_form, "#", [phx_submit: :save_name], fn f -> %>
            <%= text_input f, :name, placeholder: "Enter your name" %>
            <%= submit "Submit" %>
          <% end %>
        <% :awaiting_players -> %>
          <%= "Waiting for another player..." %>
        <% :awaiting_next_question -> %>
          <%= "Nice job!" %>
        <% :finished -> %>
          <%= case @result do %>
            <% :you_won -> %>
              <%= "You won!" %>
            <% :you_lost -> %>
              <%= "You lost!" %>
            <% :draw -> %>
              <%= "It's a draw!" %>
          <% end %>
          <%= "Your score: #{@my_score}" %>
          <%= "Opponent's score: #{@opp_score}" %>
        <% _ -> %>
          <%= form_for :question_form, "#", [phx_submit: :save_answer], fn f -> %>
            <label><%= @question.text %></label>
            <%= text_input f, :answer, placeholder: "Enter your answer" %>
            <%= submit "Submit" %>
          <% end %>
      <% end %>
    </div>
    """
  end

  def handle_event("save_name", %{"name_form" => %{"name" => name}}, socket) do
    GameServer.add_player(name)
    {:noreply, assign(socket, %{name: name, game_state: :awaiting_players})}
  end

  def handle_event("save_answer", %{"question_form" => %{"answer" => answer}}, socket) do
    GameServer.answer(answer)
    {:noreply, assign(socket, %{game_state: :awaiting_next_question})}
  end

  def handle_info({:question, question}, socket) do
    {:noreply, assign(socket, %{question: question, game_state: :awaiting_answers})}
  end

  def handle_info({:finished, players}, socket) do
    my_score = Enum.find(players, nil, & &1.name == socket.assigns.name).score
    opp_score = Enum.find(players, nil, & &1.name != socket.assigns.name).score
    result = cond do
      my_score > opp_score -> :you_won
      my_score < opp_score -> :you_lost
      true -> :draw
    end
    {:noreply, assign(socket, %{my_score: my_score, result: result, opp_score: opp_score, game_state: :finished})}
  end
end
