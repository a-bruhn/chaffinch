# TODO: Continue writing tests

defmodule Chaffinch.App.OkAction do

  @behaviour Chaffinch.App.Action

  alias Chaffinch.App.Action

  @impl Action
  @spec redo_action(Action.state(), String.t()) :: Action.new_state_tuple()
  def redo_action(model, _) do
    {:ok, model}
  end

  @impl Action
  @spec redo_action(Action.state(), String.t()) :: Action.new_state_tuple()
  def undo_action(model, _) do
    {:ok, model}
  end
end

defmodule Chaffinch.App.ErrorAction do

  @behaviour Chaffinch.App.Action

  alias Chaffinch.App.Action

  @impl Action
  @spec redo_action(Action.state(), String.t()) :: Action.new_state_tuple()
  def redo_action(model, _) do
    {:error, model}
  end

  @impl Action
  @spec redo_action(Action.state(), String.t()) :: Action.new_state_tuple()
  def undo_action(model, _) do
    {:error, model}
  end
end

defmodule ChaffinchHistoryUnitOfWorkTest do
  use ExUnit.Case
  doctest Chaffinch

  alias Chaffinch.App.{HistoryUnitOfWork, HistoryData, NullAction, OkAction, EditorState}


  @test_history_empty %HistoryData{actions: [NullAction], current_index: 0}

  @test_state_empty %EditorState{
    history: @test_history_empty
  }

  test "happy path add action to empty history" do

    state_expected = %EditorState{
      history: %HistoryData{
        actions: [OkAction, NullAction], current_index: 0
      }
    }

    assert {:ok, state_expected} == HistoryUnitOfWork.add_actions(@test_state_empty, [OkAction])
  end

end
