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

  def restart() do
    GenServer.call(__MODULE__, :restart)
  end

  def get_game_state() do
    GenServer.call(__MODULE__, :get_game_state)
  end

  def change_answer_time(answer_time) do
    GenServer.call(__MODULE__, {:change_answer_time, answer_time})
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
  def handle_call(:restart, _from, _state) do
    {:reply, :ok, %State{game_state: :awaiting_players}}
  end

  @impl true
  def handle_call(:get_game_state, _from, state) do
    {:reply, state.game_state, state}
  end

  @impl true
  def handle_call({:change_answer_time, new_answer_time}, _from, state) do
    {:reply, :ok, %{state | answer_time: new_answer_time}}
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
    if answer == Map.get(List.first(state.questions), :answer) do
      time_elapsed =
        Timex.diff(
          Timex.now(),
          Map.get(List.first(state.questions), :asked_at),
          :millisecond
        )

      points =
        round((state.answer_time - time_elapsed) / 1000)

      players =
        Enum.map(state.players, fn
          %{pid: ^pid} = player -> %{player | score: player.score + points}
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

  def handle_info(:generate_question, %State{question_amount: qa, questions: questions} = state)
      when qa <= length(questions) do
    Enum.each(state.players, fn %{pid: pid} ->
      send(pid, {:finished, state.players})
    end)

    {:noreply, %{state | game_state: :finished}}
  end

  @impl true
  def handle_info(:generate_question, state) do
    question = QuestionRepo.get_random_question()

    Enum.each(state.players, fn %{pid: pid} ->
      send(pid, {:question, question})
    end)

    # Generate next question after the answer time is over
    Process.send_after(self(), :generate_question, state.answer_time)

    {:noreply, %{state | game_state: :awaiting_answers, questions: [question | state.questions]}}
  end
end
