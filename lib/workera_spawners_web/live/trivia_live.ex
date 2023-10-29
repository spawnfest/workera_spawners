defmodule WorkeraSpawnersWeb.TriviaLive do
  use WorkeraSpawnersWeb, :live_view

  alias WorkeraSpawners.GameServer

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
      game_state: GameServer.get_game_state(),
      name: nil,
      question: nil
      )
    }
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <%= case {@game_state, @name} do %>
        <% {:awaiting_players, nil} -> %>
          <%= form_for :name_form, "#", [phx_submit: :save_name], fn f -> %>
            <%= text_input f, :name, placeholder: "Enter your name" %>
            <%= submit "Submit" %>
          <% end %>
        <% {_, nil} -> %>
          <p class="message error"> Game going on, please wait </p>
        <% {:awaiting_players, _name} -> %>
          <p class="message waiting">Waiting for other players!</p>
        <% {:awaiting_next_question, _name} -> %>
          <p class="message success"> Nice job! </p>
        <% {:finished, _name} -> %>
          <%= case @result do %>
            <% :you_won -> %>
              <p class="message success"> You won! </p>
              <br/>
            <% :you_lost -> %>
              <p class="message waiting"> You Lost! </p>
              <br/>
            <% :draw -> %>
            <p class="message success"> It's a draw! </p>
              <br/>
          <% end %>
          <%= "Your score: #{@my_score}" %>
          <br/>
          <%= "Opponent's score: #{@opp_score}" %>
          <br/>
          <button phx-click="restart">Restart</button>
        <% {:awaiting_answers, _name} -> %>
          <%= case @question do %>
            <% nil -> %>
              <p>Waiting for question!</p>
            <% _ -> %>
              <%= form_for :question_form, "#", [phx_submit: :save_answer], fn f -> %>
                <label><%= @question.text %></label>
                <%= text_input f, :answer, placeholder: "Enter your answer", type: "text" %>
                <%= submit "Submit", type: "submit" %>
              <% end %>
            <% end %>
        <% end %>
    </div>
    """
  end

  def handle_event("save_name", %{"name_form" => %{"name" => name}}, socket) do
    case GameServer.add_player(name) do
      :ok ->
        {:noreply, assign(socket, game_state: GameServer.get_game_state(), name: name)}
      _else ->
        {:noreply, assign(socket, game_state: GameServer.get_game_state())}
    end
  end

  def handle_event("restart", _params, socket) do
    GameServer.restart()
    {:noreply, assign(socket,
      %{
        game_state: GameServer.get_game_state(),
        name: nil,
        question: nil
      })
    }
  end

  def handle_event("save_answer", %{"question_form" => %{"answer" => answer}}, socket) do
    GameServer.answer(answer)
    {:noreply, assign(socket, %{game_state: :awaiting_next_question})}
  end

  def handle_info({:question, question}, socket) do
    IO.inspect(question)
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
