defmodule Chaffinch.Model.EditorCursor do
  defstruct x: 0,
            y: 0,
            offset_x: 0,
            offset_y: 0
end

defmodule Chaffinch.Model.EditorText do
  defstruct text: "",
            offset_x: 0,
            offset_y: 0
end

defmodule Chaffinch.Model.EditorState do
  alias Chaffinch.Model.{EditorText, EditorCursor}

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
