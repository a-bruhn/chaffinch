defmodule Chaffinch.App do
  @moduledoc """
  Main application module
  """

  @behaviour Ratatouille.App

  import Ratatouille.Constants, only: [key: 1, color: 1]
  import Ratatouille.View
  import Ratatouille.Window

  require ExTermbox.Bindings

  alias Ratatouille.Runtime.{Command, Subscription}
  alias Chaffinch.App.{Cursor, Text, EditorState, CursorData, FileData, State, View}

  @tab_size 4
  @cursor_offset_x 4
  @cursor_offset_y 3

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
  @quit_key key(:ctrl_q)

  @nochar_noctrl_keys @cursor_keys ++
                        [
                          @spacebar,
                          @enter,
                          @tab_key,
                          @delete_key,
                          @backspace1,
                          @backspace2,
                          @save_key,
                          @quit_key
                        ]

  @doc """
  Perform initial setup and output the initial app state.
  """
  @impl true
  def init(_context) do
    Cursor.show_cursor()
    ExTermbox.Bindings.set_cursor(@cursor_offset_x, @cursor_offset_y)

    full_path = System.get_env("CHAFFINCH_FILE")

    fileinfo =
      case full_path do
        nil -> nil
        _ -> %FileData{filename: Path.basename(full_path), path: Path.dirname(full_path)}
      end

    initial_state = %EditorState{
      cursor: %CursorData{offset_x: @cursor_offset_x, offset_y: @cursor_offset_y},
      fileinfo: fileinfo
    }

    case fileinfo do
      nil -> initial_state
      _ -> initial_state |> Text.import_text()
    end
    |> State.update_status_msg()
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
          @save_key -> State.process_save_command(model)
          @quit_key -> State.process_quit_command(model)
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
    model
    |> View.render_active_view()
  end
end
