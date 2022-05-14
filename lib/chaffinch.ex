defmodule Chaffinch do
  @moduledoc """
  Main module running the Ratatouille event loop.
  """

  @behaviour Ratatouille.App

  import Ratatouille.Constants, only: [key: 1]
  import Ratatouille.View
  require Cursor
  require ExTermbox.Bindings

  @app_title "Chaffinch Text Editor"

  @tab_size 4
  @cursor_offset_x 4
  @cursor_offset_y 2

  @up key(:arrow_up)
  @down key(:arrow_down)
  @left key(:arrow_left)
  @right key(:arrow_right)
  @home key(:home)
  @end_key key(:end)
  @cursor_keys [
    @up,
    @down,
    @left,
    @right,
    @home,
    @end_key
  ]

  @spacebar key(:space)
  @enter key(:enter)
  @tab_key key(:tab)

  @delete_key key(:delete)

  @backspace1 key(:backspace)
  @backspace2 key(:backspace2)

  @nochar_noctrl_keys @cursor_keys ++ [
    @spacebar,
    @enter,
    @tab_key,
    @delete_key,
    @backspace1,
    @backspace2
  ]

  @doc """
  Perform initial setup and output the initial app state.
  """
  def init(_context) do

    Cursor.show_cursor
    ExTermbox.Bindings.set_cursor(@cursor_offset_x, @cursor_offset_y)
    %EditorState{cursor: %EditorCursor{offset_x: @cursor_offset_x, offset_y: @cursor_offset_y}}

  end

  @doc """
  Update the model based on the occuring event.
  """
  def update(model, msg) do
    case msg do
      {:event, %{key: key}} when key in @nochar_noctrl_keys ->
        case key do
          @up -> Cursor.move(model, :up)
          @down -> Cursor.move(model, :down)
          @left -> Cursor.move(model, :left)
          @right -> Cursor.move(model, :right)
          @home -> Cursor.move(model, :home)
          @end_key -> Cursor.move(model, :end)
          @tab_key -> Text.insert_char(model, model.tab)
          @spacebar -> Text.insert_char(model, <<0x20>>)
          @enter -> Text.insert_linebreak(model)
          @delete_key -> Text.fwd_remove_char(model)
          @backspace1 -> Text.bwd_remove_char(model)
          @backspace2 -> Text.bwd_remove_char(model)
          _ -> model
        end
      {:event, %{ch: ch}} when ch > 0 -> Text.insert_char(model, <<ch::utf8>>)
      _ -> model
    end
  end

  @doc """
  Output the model state to the terminal.
  """
  def render(model) do
    view do
      panel(title: @app_title, height: :fill) do
        for {textrow, idx} <- Enum.with_index(model.textrows) do
          label(content: "#{idx + 1} #{textrow |> Map.get(:text)}")
        end
        # Debugging output
        label(content: "CX: #{model.cursor.x} -- CY #{model.cursor.y} " <> 
          "-- LL #{Text.line_size(model) |> elem(1)} -- NROW #{length(model.textrows)}")
      end
    end
  end
end

Ratatouille.run(
  Chaffinch,
  quit_events: [
    {:key, Ratatouille.Constants.key(:ctrl_q)}
  ]
)
