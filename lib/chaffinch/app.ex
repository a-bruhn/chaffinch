defmodule Chaffinch.App do
  @moduledoc """
  Main application module
  """

  @behaviour Ratatouille.App

  import Ratatouille.Constants, only: [key: 1]

  require ExTermbox.Bindings

  alias Ratatouille.Runtime.{Subscription}
  alias Chaffinch.App.{Cursor, Text, EditorState, CursorData, FileData, State, View}

  @tab_size 4

  @deadspace_left 2
  @deadspace_top 3
  @deadspace_right 2
  @deadspace_bottom 3
  @padding 2

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
  @escape key(:esc)

  @nochar_keys @cursor_keys ++
                 [
                   @spacebar,
                   @enter,
                   @tab_key,
                   @delete_key,
                   @backspace1,
                   @backspace2,
                   @save_key,
                   @quit_key,
                   @escape
                 ]

  @doc """
  Perform initial setup and output the initial app state.
  """
  @impl true
  def init(%{window: window}) do
    Cursor.show_cursor()
    ExTermbox.Bindings.set_cursor(@deadspace_left + @padding, @deadspace_top)

    full_path = System.get_env("CHAFFINCH_FILE")

    fileinfo =
      case full_path do
        nil -> nil
        _ -> %FileData{filename: Path.basename(full_path), path: Path.dirname(full_path)}
      end

    initial_state = %EditorState{
      cursor: %CursorData{},
      fileinfo: fileinfo,
      window: window,
      deadspace: %{
        t: @deadspace_top,
        b: @deadspace_bottom,
        l: @deadspace_left,
        r: @deadspace_right,
        p: @padding
      }
    }

    case fileinfo do
      nil -> initial_state
      _ -> initial_state |> Text.import_text()
    end
    |> State.update_status_msg()
  end

  @doc """
  Update the model based on the occuring event.

  #TODO: Improve readability
  """
  @impl true
  def update(model, msg) do
    case msg do
      {:event, %{key: key}} when key in @nochar_keys ->

        case key do
          @save_key -> State.process_save_command(model)
          @quit_key -> State.process_quit_command(model)
          @escape -> State.return_to_text(model)
          _ ->
          cond do
            State.is_editable?(model) -> # push down: tell, don't ask!
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
                @escape -> State.return_to_text(model)
                _ -> model
              end

            true -> model
          end
          _ -> model
        end

      {:event, %{ch: ch}} when ch > 0 ->
        Text.insert_char(model, <<ch::utf8>>)

      {:event, %{resize: event}} ->
        State.resize_window(model, event)

      _ ->
        model
    end
    |> State.sync_view()
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
