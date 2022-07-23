defmodule Chaffinch.App.HistoryUnitOfWork do

  alias Chaffinch.App.{HistoryData, Nullaction, CursorAction, TextAction, SelectionAction, TextAction}

  @moduledoc """
  HistoryUnitOfWork provides atomic operations on the application state through Actions
  """

  @doc """
  Redo all available operations from current_index until a NullAction is encountered
  or current_index > length(actions). Build a temporary editor state and return it if
  all actions yield :ok, update status message.
  """
  def go_forward(model) do
  end

  @doc """
  Undo all available operations from current_index until a NullAction is encountered
  or current_index = 0. Build a temporary editor state and return it if
  all actions yield :ok, update status message.
  """
  def go_backward(model) do
  end

  @doc """
  Extend the list of actions from current_index after pruning all existing actions in history
  after current_index. Then go forward once and call actions to be performed.
  """
  def add_actions(model, actions) do
  end

  defp _prune_stale_actions(history) do
  end

end
