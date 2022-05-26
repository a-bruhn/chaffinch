defmodule Chaffinch.App.CursorData do
  defstruct x: 0,
            y: 0,
            offset_x: 0,
            offset_y: 0
end

defmodule Chaffinch.App.TextData do
  defstruct text: "",
            offset_x: 0,
            offset_y: 0
end

defmodule Chaffinch.App.FileData do
  require Logger

  defstruct [
    :filename,
    :path
  ]
end

defmodule Chaffinch.App.EditorState do
  alias Chaffinch.App.{TextData, CursorData}

  defstruct [
    :fileinfo,
    :statusmsg,
    textrows: [
      %TextData{text: "You may edit me."},
      %TextData{text: "I promise not to be mad."}
    ],
    cursor: %CursorData{},
    dirty: 0,
    tab: "    "
  ]
end
