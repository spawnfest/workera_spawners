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

      assert GameServer.get_score() == 1
    end

    test "score after an incorrect answer" do
      :ok = GameServer.add_player("John Doe")
      :ok = GameServer.add_player("Michael Mustermann")

      GameServer.answer("wrong")

      assert GameServer.get_score() == 0
    end
  end
end
