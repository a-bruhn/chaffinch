defmodule Chaffinch.App.CursorData do
  defstruct x: 0,
            y: 0
end

defmodule Chaffinch.App.TextData do
  defstruct text: ""
end

defmodule Chaffinch.App.FileData do
  defstruct [
    :filename,
    :path
  ]
end

defmodule Chaffinch.App.HistoryData do
  defstruct [
    actions: [],
    current_index: 0
  ]

  @doc """
  Insert an operation at a given index
  """
  def insert_operation(operation, index) do
  end

  @doc """
  Delete an operation at a given index
  """
  def delete_operation(index) do
  end

end

defmodule Chaffinch.App.EditorState do
  alias Chaffinch.App.{TextData, CursorData, HistoryData}

  defstruct [
    :fileinfo,
    :window,
    offset_x: 0,
    offset_y: 0,
    active_view: :text,
    status_msg: {:ok, ""},
    textrows: [%TextData{}],
    cursor: %CursorData{},
    dirty: 0,
    tab: "    ",
    deadspace: %{t: 0, b: 0, l: 0, r: 0, p: 0},
    selection: {%CursorData{}, %CursorData{}},
    history: %HistoryData{}
  ]
end
