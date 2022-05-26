defmodule Chaffinch.App do
  @moduledoc """
  Main application module
  """

  @behaviour Ratatouille.App

  import Ratatouille.Constants, only: [key: 1]
  import Ratatouille.View
  import Ratatouille.Window
  require ExTermbox.Bindings

  alias Ratatouille.Runtime.{Command, Subscription}

  alias Chaffinch.App.{Cursor, Text, EditorState, CursorData, FileData}

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

  @save_key key(:ctrl_s)

  @nochar_noctrl_keys @cursor_keys ++
                        [
                          @spacebar,
                          @enter,
                          @tab_key,
                          @delete_key,
                          @backspace1,
                          @backspace2,
                          @save_key
                        ]

  @doc """
  Perform initial setup and output the initial app state.
  """
  @impl true
  def init(_context) do
    Cursor.show_cursor()
    ExTermbox.Bindings.set_cursor(@cursor_offset_x, @cursor_offset_y)

    %EditorState{
      cursor: %CursorData{offset_x: @cursor_offset_x, offset_y: @cursor_offset_y},
      fileinfo: %FileData{filename: "welcome.txt", path: File.cwd!()}
    }
    |> Text.import_text()
  end

  @doc """
  Update the model based on the occuring event.
  """
  @impl true
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
          @save_key -> Text.save_text(model)
          _ -> model
        end

      {:event, %{ch: ch}} when ch > 0 ->
        Text.insert_char(model, <<ch::utf8>>)

      _ ->
        model
    end
  end

  @impl true
  def subscribe(_model) do
    Subscription.interval(1_000, :tick)
  end

  @doc """
  Output the model state to the terminal.
  """
  @impl true
  def render(model) do
    b_bar =
      bar do
        label(content: "Quit: Hold CTRL-Q | Save: CTRL-S")
      end

    view bottom_bar: b_bar do
      panel(title: @app_title, height: :fill) do
        for {textrow, idx} <- Enum.with_index(model.textrows) do
          label(content: "#{idx + 1} #{textrow |> Map.get(:text)}")
        end
      end

      # Debugging output
      # label(
      #  content:
      #    "CX: #{model.cursor.x} -- CY #{model.cursor.y} " <>
      #      "-- LL #{Text.line_size(model) |> elem(1)} -- NROW #{length(model.textrows)}"
      # )
    end
  end
end
