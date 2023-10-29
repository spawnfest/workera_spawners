defmodule WorkeraSpawners.GameServerTest do
  use ExUnit.Case, async: false

  alias WorkeraSpawners.GameServer

  setup do
    WorkeraSpawners.GameServer.restart()
    :ok
  end

  describe "get_game_state/0" do
    test "initial game_state is :awaiting_players" do
      assert GameServer.get_game_state() == :awaiting_players
    end
  end

  describe "add_player/1" do
    test "adds first player" do
      :ok = GameServer.add_player("John Doe")
      assert GameServer.get_game_state() == :awaiting_players
    end

    test "adds second player" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")
      assert GameServer.get_game_state() == :awaiting_answers
    end

    test "does not allow third player" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      assert GameServer.get_game_state() == :awaiting_answers

      resp = GameServer.add_player("Fifth Wheel")
      assert resp == :error
    end
  end

  describe "generating first question" do
    test "both players receive first question" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      assert_receive({:question, _})
      assert_receive({:question, _})
    end
  end

  describe "answer/1" do
    test "answering wrong" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      resp = GameServer.answer("wrong")
      assert resp == :incorrect
    end

    test "answering correct" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      question =
        receive do
          {:question, question} -> question
        end

      resp = GameServer.answer(question.answer)
      assert resp == :correct
    end
  end

  describe "get_score/0" do
    test "initial score" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      assert GameServer.get_score() == 0
    end

    test "score after a correct answer" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      question =
        receive do
          {:question, question} -> question
        end

      :correct = GameServer.answer(question.answer)

      assert GameServer.get_score() == 30
    end

    test "score after an incorrect answer" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      GameServer.answer("wrong")

      assert GameServer.get_score() == 0
    end

    test "score after a correct answer with waiting time" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      question =
        receive do
          {:question, question} -> question
        end

      :timer.sleep(2000)

      :correct = GameServer.answer(question.answer)

      assert GameServer.get_score() == 28
    end
  end

  describe "receive second question" do
    test "both players receive second question" do
      GameServer.change_answer_time(50)
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      assert_receive({:question, _})
      assert_receive({:question, _})

      :timer.sleep(100)

      assert_receive({:question, _})
      assert_receive({:question, _})
    end
  end

  describe "stop after 3 questions" do
    test "the game stops and sends the finished message" do
      GameServer.change_answer_time(50)
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      :timer.sleep(300)

      assert GameServer.get_game_state() == :finished
      assert_receive({:finished, _})
    end
  end
end
