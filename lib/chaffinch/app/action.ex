defmodule Chaffinch.App.Action do

  alias Chaffinch.App.EditorState

  @type state :: %EditorState{}
  @type level :: {:ok, :error, :null}
  @type new_state_tuple :: {level(), state()}

  @callback redo_action(state(), String.t()) :: new_state_tuple()
  @callback undo_action(state(), String.t()) :: new_state_tuple()

end

defmodule Chaffinch.App.NullAction do

  @behaviour Chaffinch.App.Action

  alias Chaffinch.App.Action

  @impl Action
  @spec redo_action(Action.state(), String.t()) :: Action.new_state_tuple()
  def redo_action(model, _) do
    {:null, model}
  end

  @impl Action
  @spec undo_action(Action.state(), String.t()) :: Action.new_state_tuple()
  def undo_action(model, _) do
    {:null, model}
  end
end

defmodule Chaffinch.App.CursorAction do

end

defmodule Chaffinch.App.TextAction do

end

defmodule Chaffinch.App.SelectionAction do

end

defmodule Chaffinch.App.OptionAction do

end
