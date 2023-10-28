defmodule WorkeraSpawnersWeb.CounterLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use WorkeraSpawnersWeb, :live_view

  def render(assigns) do
    ~H"""
    Your counter: <%= @counter %>
    <button phx-click="inc_counter">+</button>
    <button phx-click="dec_counter">-</button>
    """
  end

  def mount(_params, _session, socket) do
    counter = 0
    {:ok, assign(socket, :counter, counter)}
  end

  def handle_event("inc_counter", _params, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def handle_event("dec_counter", _params, socket) do
    {:noreply, update(socket, :counter, &(&1 - 1))}
  end
end
