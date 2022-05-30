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

defmodule Chaffinch.App.EditorState do
  alias Chaffinch.App.{TextData, CursorData}

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
    deadspace: %{t: 0, b: 0, l: 0, r: 0, p: 0}
  ]
end
