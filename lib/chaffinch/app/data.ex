defmodule Chaffinch.App.EditorCursor do
  defstruct x: 0,
            y: 0,
            offset_x: 0,
            offset_y: 0
end

defmodule Chaffinch.App.EditorText do
  defstruct text: "",
            offset_x: 0,
            offset_y: 0
end

defmodule Chaffinch.App.EditorState do
  alias Chaffinch.App.{EditorText, EditorCursor}

  defstruct [
    :filename,
    textrows: [
      %EditorText{text: "You may edit me."},
      %EditorText{text: "I promise not to be mad."}
    ],
    cursor: %EditorCursor{},
    dirty: 0,
    tab: "    "
  ]
end
