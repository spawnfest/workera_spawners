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
    <%= case @game_state do %>
      <% :awaiting_name -> %>
        <%= form_for :name_form, "#", [phx_submit: :save_name], fn f -> %>
          <%= text_input f, :name, placeholder: "Enter your name" %>
          <%= submit "Submit" %>
        <% end %>
      <% :awaiting_players -> %>
        <%= "Waiting for another player..." %>
      <% :finished -> %>
        <!-- Finished game... -->
      <% _ -> %>
        <%= form_for :question_form, "#", [phx_submit: :save_answer], fn f -> %>
          <label><%= @question.text %></label>
          <%= text_input f, :answer, placeholder: "Enter your answer" %>
          <%= submit "Submit" %>
        <% end %>
    <% end %>
    """
  end

  def handle_event("save_name", %{"name_form" => %{"name" => name}}, socket) do
    GameServer.add_player(name)
    {:noreply, assign(socket, %{name: name, game_state: :awaiting_players})}
  end

  def handle_event("save_answer", %{"question_form" => %{"answer" => _answer}}, socket) do

    {:noreply, socket}
  end

  def handle_info({:question, question}, socket) do
    {:noreply, assign(socket, %{question: question, game_state: :awaiting_answers})}
  end
end
