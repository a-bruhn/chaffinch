defmodule EditorCursor do
  defstruct x: 0,
            y: 0,
            offset_x: 0,
            offset_y: 0
end

defmodule EditorText do
  defstruct text: "",
            offset_x: 0,
            offset_y: 0
end

defmodule EditorState do
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
