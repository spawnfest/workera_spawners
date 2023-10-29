defmodule WorkeraSpawners.GameServer do
  use GenServer

  alias WorkeraSpawners.GameServer.Player
  alias WorkeraSpawners.GameServer.QuestionRepo
  alias WorkeraSpawners.GameServer.State

  @doc """
  Starts the game server.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_game_state() do
    GenServer.call(__MODULE__, :get_game_state)
  end

  def add_player(name) do
    GenServer.call(__MODULE__, {:add_player, name})
  end

  def answer(answer) do
    GenServer.call(__MODULE__, {:answer, answer})
  end

  def get_score() do
    GenServer.call(__MODULE__, :get_score)
  end

  @impl true
  def init(:ok) do
    {:ok, %State{game_state: :awaiting_players}}
  end

  @impl true
  def handle_call(:get_game_state, _from, state) do
    {:reply, state.game_state, state}
  end

  @impl true
  def handle_call({:add_player, name}, {pid, _}, %{game_state: :awaiting_players} = state) do
    players = state.players ++ [%Player{pid: pid, name: name}]

    if length(players) == 2 do
      send(self(), :generate_question)
    end

    state = %{state | players: players}

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:add_player, _name}, _from, state) do
    {:reply, :error, state}
  end

  @impl true
  def handle_call({:answer, answer}, {pid, _}, state) do
    if answer == state.question.answer do
      players =
        Enum.map(state.players, fn
          %{pid: ^pid} = player -> %{player | score: player.score + 1}
          player -> player
        end)

      {:reply, :correct, %{state | players: players}}
    else
      {:reply, :incorrect, state}
    end
  end

  @impl true
  def handle_call(:get_score, {pid, _}, state) do
    player = Enum.find(state.players, fn player -> player.pid == pid end)

    {:reply, player.score, state}
  end

  @impl true
  def handle_info(:generate_question, state) do
    question = QuestionRepo.get_random_question()

    Enum.each(state.players, fn %{pid: pid} ->
      send(pid, {:question, question})
    end)

    state = %{state | game_state: :awaiting_answers, question: question}
    {:noreply, state}
  end
end
