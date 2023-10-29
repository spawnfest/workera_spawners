defmodule WorkeraSpawnersWeb.TriviaLive do
  use WorkeraSpawnersWeb, :live_view

  alias WorkeraSpawners.GameServer

  def mount(_params, _session, socket) do
    server = GameServer.start_link(__MODULE__)
    {
      :ok,
      socket
      |> assign(
      server: server,
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
        <!-- Waiting for server event... -->
      <% :finished -> %>
        <!-- Finished game... -->
      <% _ -> %>
        <%= form_for :question_form, "#", [phx_submit: :save_answer], fn f -> %>
          <label><%= @question %></label>
          <%= text_input f, :answer, placeholder: "Enter your answer" %>
          <%= submit "Submit" %>
        <% end %>
    <% end %>
    """
  end

  def handle_event("save_name", %{"name_form" => %{"name" => name}}, %{assigns: %{server: s}} = socket) do
    {:noreply, assign(socket, :name, name)}
  end

  def handle_event("save_answer", %{"question_form" => %{"answer" => _answer}}, socket) do
    # Handle answer submission
    {:noreply, socket}
  end

  def handle_info({:question, question}, state, socket) do
    {:noreply, assign(socket, %{game_state: state, question: question})}
  end
end
