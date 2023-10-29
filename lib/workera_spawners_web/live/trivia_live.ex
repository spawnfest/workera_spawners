defmodule WorkeraSpawnersWeb.TriviaLive do
  alias WorkeraSpawners.GameServerTest
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
    <%= case {@game_state, @name, @question} do %>
      <% {:awaiting_players, nil, _question} -> %>
        <%= form_for :name_form, "#", [phx_submit: :save_name], fn f -> %>
          <%= text_input(f, :name, placeholder: "Enter your name") %>
          <%= submit("Submit") %>
        <% end %>
      <% {_, nil, _} -> %>
        <p>Game going on, please wait</p>
      <% {:awaiting_players, _name, _question} -> %>
        <p>Waiting for other players!</p>
      <% {:awaiting_answers, _name, nil} -> %>
        <p>Waiting for question!</p>
      <% {:awaiting_answers, _name, question} -> %>
        <%= form_for :question_form, "#", [phx_submit: :save_answer], fn f -> %>
          <label><%= question.text %></label>
          <%= text_input(f, :answer, placeholder: "Enter your answer") %>
          <%= submit("Submit") %>
        <% end %>
      <% {:finished, _name, _question} -> %>
        <p>Game finished</p>
    <% end %>
    """
  end

  def handle_event(
        "save_name",
        %{"name_form" => %{"name" => name}},
        socket
      ) do
    case GameServer.add_player(name) do
      :ok ->
        {:noreply, assign(socket, game_state: GameServer.get_game_state(), name: name)}

      _else ->
        {:noreply, assign(socket, game_state: GameServer.get_game_state())}
    end
  end

  def handle_event("save_answer", %{"question_form" => %{"answer" => answer}}, socket) do
    case GameServer.answer(answer) do
      :correct ->
        {:noreply, assign(socket, question: nil)}

      :incorrect ->
        {:noreply, socket}
    end
  end

  def handle_info({:question, question}, socket) do
    {:noreply, assign(socket, %{game_state: GameServer.get_game_state(), question: question})}
  end

  def handle_info({:finished, players}, socket) do
    {:noreply, assign(socket, %{game_state: GameServer.get_game_state(), question: nil})}
  end
end
