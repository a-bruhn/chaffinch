# TODO: Refactor bad design: Entangle everything, separate concerns, and move complexity into Actions!
#  Increase the overall amount of status handling
#  Add type specs

defmodule Chaffinch.App.Text do
  @moduledoc """
  Operations on text stored within the row-wise list of text structs inside the model struct.
  """

  alias Chaffinch.App.{Cursor, State, TextData, FileIO}

  require Logger

  defp _insert_chars(row_text, chars, pos) do
    String.split_at(row_text, pos)
    |> Tuple.insert_at(1, chars)
    |> Tuple.to_list()
    |> Enum.join()
  end

  defp _remove_chars(row_text, start_idx, end_idx) do
    {part1, part2} = String.split_at(row_text, start_idx)
    {_, part2_new} = String.split_at(part2, end_idx - start_idx)

    [part1, part2_new] |> Enum.join()
  end

  @doc """
  Import a textfile into the editor
  """
  def import_text(model) do
    Path.join(model.fileinfo.path, model.fileinfo.filename)
    |> FileIO.import_file()
    |> case do
      {:ok, new_textrows_list} ->
        new_model = State.update_status_msg(model)
        put_in(new_model.textrows, new_textrows_list)

      {:error, _} ->
        State.update_status_msg(model, "ERROR: Cannot load #{model.fileinfo.filename}.")
    end
  end

  @doc """
  Save the current state of the text
  """
  def save_text(model) do
    path = Path.join(model.fileinfo.path, model.fileinfo.filename)
    text_len = length(model.textrows)
    last_line = List.last(model.textrows).text

    model.textrows
    |> Enum.map(fn x -> x.text <> "\n" end)
    |> List.replace_at(text_len - 1, last_line)
    |> Enum.join()
    |> FileIO.write_file(path)
    |> case do
      {:ok, _} ->
        %{model | dirty: 0} |> State.update_status_msg()

      {:error, _} ->
        State.update_status_msg(model, "ERROR: Cannot save #{model.fileinfo.filename}.")
    end
  end

  @doc """
  Merge two text rows at index `idx`
  """
  def merge_lines(model, idx) do
    row1 = model |> row_text(idx)
    row2 = model |> row_text(idx + 1)

    new_textrow = [row1, row2] |> Enum.join()

    new_textrows_list =
      List.replace_at(model.textrows, idx, %TextData{text: new_textrow})
      |> List.delete_at(idx + 1)

    put_in(model.textrows, new_textrows_list)
  end

  @doc """
  Split current row of text into two rows
  """
  def split_row(model) do
    [this_line | next_line] = String.split_at(row_text(model), model.cursor.x) |> Tuple.to_list()

    model
    |> add_row(Enum.join(next_line))
    |> update_row(%TextData{text: this_line})
    |> Cursor.move_right()
    |> Cursor.sync_cursor()
    |> State.make_dirty()
  end

  @doc """
  Replace the row at the current cursor y position with `new_textrow`
  """
  def update_row(model, new_textrow) do
    put_in(model.textrows, List.replace_at(model.textrows, model.cursor.y, new_textrow))
  end

  @doc """
  Replace the row at y-index `idx` with `new_textrow`
  """
  def update_row(model, new_textrow, idx) do
    put_in(model.textrows, List.replace_at(model.textrows, idx, new_textrow))
  end

  @doc """
  Get the row at the current cursor y position
  """
  def row(model), do: Enum.at(model.textrows, model.cursor.y)

  @doc """
  Get the row at y-index `idx`
  """
  def row(model, idx), do: Enum.at(model.textrows, idx)

  @doc """
  Get the length of the current line
  """
  def line_size(model), do: {:ok, String.length(row_text(model))}

  @doc """
  Get the length of the line at y-index `idx`
  """
  def line_size(model, idx) do
    cond do
      idx not in 0..(length(model.textrows) - 1) -> {:error, :ioob}
      true -> {:ok, String.length(row_text(model, idx))}
    end
  end

  @doc """
  Get the text of the current line
  """
  def row_text(model), do: row(model) |> Map.get(:text)

  @doc """
  Get the text of the line at y-index `idx`
  """
  def row_text(model, idx), do: row(model, idx) |> Map.get(:text)

  @doc """
  Insert chars at the current cursor position
  """
  def insert_char(model, chars) do
    new_rowtext =
      model
      |> row_text
      |> _insert_chars(chars, model.cursor.x)

    model
    |> update_row(%{row(model) | text: new_rowtext})
    |> Cursor.move_right(true)
    |> Cursor.sync_cursor()
    |> State.make_dirty()
  end

  @doc """
  Forward remove a char at the current cursor position
  """
  def fwd_remove_char(model) do
    current_row_text = model |> row_text

    model
    |> Cursor.pos_in_line()
    |> case do
      {:error, reason} ->
        Logger.error("Cannot forward delete char due to: #{reason}")
        model

      {:ok, :line_end} ->
        cond do
          Cursor.can_move_down?(model) ->
            model |> merge_lines(model.cursor.y)

          true ->
            model
        end

      {:ok, _} ->
        new_text = _remove_chars(current_row_text, model.cursor.x, model.cursor.x + 1)

        model
        |> update_row(%TextData{text: new_text})
    end
    |> Cursor.sync_cursor()
    |> State.make_dirty()
  end

  @doc """
  Backward remove a char at the current cursor position
  """
  def bwd_remove_char(model) do
    current_row_text = model |> row_text

    model
    |> Cursor.pos_in_line()
    |> case do
      {:error, reason} ->
        Logger.error("Cannot forward delete char due to: #{reason}")
        model

      {:ok, :line_beginning} ->
        cond do
          model.cursor.y != 0 ->
            model
            |> Cursor.move_left()
            |> merge_lines(model.cursor.y - 1)

          true ->
            model
        end

      {:ok, :line_end} ->
        cond do
          model.cursor.y != 0 and line_size(model) == {:ok, 0} ->
            model
            |> Cursor.move_left()
            |> merge_lines(model.cursor.y - 1)

          true ->
            new_text = _remove_chars(current_row_text, model.cursor.x - 1, model.cursor.x)

            model
            |> update_row(%TextData{text: new_text})
            |> Cursor.move_left()
        end

      {:ok, :in_line} ->
        new_text = _remove_chars(current_row_text, model.cursor.x - 1, model.cursor.x)

        model
        |> update_row(%TextData{text: new_text})
        |> Cursor.move_left()
    end
    |> Cursor.sync_cursor()
    |> State.make_dirty()
  end

  @doc """
  Add a linebreak at the current cursor position
  """
  def insert_linebreak(model) do
    model
    |> Cursor.pos_in_line()
    |> case do
      {:error, reason} ->
        Logger.error("Cannot insert line break due to: #{reason}")
        model

      {:ok, :line_end} ->
        model |> add_row |> Cursor.move_right()

      {:ok, :in_line} ->
        model |> split_row

      {:ok, :line_beginning} ->
        model |> add_row("", model.cursor.y) |> Cursor.move_down()
    end
    |> Cursor.sync_cursor()
    |> State.make_dirty()
  end

  @doc """
  Add an empty row after the current cursor y-position
  """
  def add_row(model),
    do:
      put_in(
        model.textrows,
        List.insert_at(model.textrows, model.cursor.y + 1, %TextData{})
      )

  @doc """
  Add a new row with text `new_row_text` after the current cursor y-position
  """
  def add_row(model, new_row_text),
    do:
      put_in(
        model.textrows,
        List.insert_at(model.textrows, model.cursor.y + 1, %TextData{text: new_row_text})
      )

  @doc """
  Add a new row with text `new_row_text` at the y-index `idx`
  """
  def add_row(model, new_row_text, idx),
    do:
      put_in(
        model.textrows,
        List.insert_at(model.textrows, idx, %TextData{text: new_row_text})
      )
end

defmodule Chaffinch.App.Cursor do
  @moduledoc """
  Operations on the cursor stored in the cursor struct inside the model struct.
  """

  require ExTermbox.Bindings
  require IO.ANSI.Sequence
  require Logger

  alias Chaffinch.App.{Text, State}

  IO.ANSI.Sequence.defsequence(:_show_cursor, "?25", "h")
  IO.ANSI.Sequence.defsequence(:_hide_cursor, "?25", "l")

  def show_cursor, do: IO.puts(_show_cursor())
  def hide_cursor, do: IO.puts(_hide_cursor())

  @doc """
  Set the displayed cursor position to the position stored in the model
  """
  def sync_cursor(model) do
    ExTermbox.Bindings.set_cursor(
      model.cursor.x + model.deadspace.l + model.deadspace.p - model.offset_x,
      model.cursor.y + model.deadspace.t - model.offset_y
    )

    model
  end

  @doc """
  Is there room for the cursor to move one step down?
  """
  def can_move_down?(model) when model.cursor.y < length(model.textrows) - 1, do: true
  def can_move_down?(_other), do: false

  @doc """
  Get the relative position within a row of text
  """
  def pos_in_line(model) do
    model
    |> Text.line_size()
    |> case do
      {:error, reason} ->
        Logger.error("Position not in line not determinable due to: #{reason}")
        model

      {:ok, lsize} ->
        cond do
          model.cursor.x == lsize -> {:ok, :line_end}
          model.cursor.x == 0 -> {:ok, :line_beginning}
          model.cursor.x < lsize -> {:ok, :in_line}
          true -> {:error, :cx_indeterminate}
        end
    end
  end

  @doc """
  Move the cursor in direction `where_to`
  """
  def move(model, where_to) do
    case where_to do
      :left -> model |> move_left
      :right -> model |> move_right
      :up -> model |> move_up
      :down -> model |> move_down
      :home -> model |> carriage_return
      :end -> model |> goto_end
    end
    |> sync_cursor
    |> State.update_status_msg()
  end

  @doc """
  If possible, move the cursor one step to the left
  """
  def move_left(model) do
    {_status, lsize} = Text.line_size(model, model.cursor.y - 1)

    model
    |> Text.line_size(model.cursor.y)
    |> case do
      {:error, reason} ->
        Logger.debug("Cannot move left due to: #{reason}")
        model

      {:ok, _lsize} ->
        cond do
          model.cursor.x != 0 ->
            put_in(model.cursor, %{model.cursor | x: model.cursor.x - 1})

          model.cursor.y > 0 ->
            put_in(model.cursor, %{model.cursor | y: model.cursor.y - 1, x: lsize})

          true ->
            model
        end
    end
  end

  @doc """
  If possible, move the cursor one step to the right
  """
  def move_right(model, char_insert \\ false) do
    cond do
      char_insert ->
        put_in(model.cursor, %{model.cursor | x: model.cursor.x + 1})

      true ->
        model
        |> pos_in_line
        |> case do
          {:error, reason} ->
            Logger.debug("Cannot move right due to: #{reason}")
            model

          {:ok, :line_end} ->
            cond do
              can_move_down?(model) ->
                put_in(model.cursor, %{model.cursor | y: model.cursor.y + 1, x: 0})

              true ->
                model
            end

          {:ok, _} ->
            put_in(model.cursor, %{model.cursor | x: model.cursor.x + 1})
        end
    end
  end

  @doc """
  If possible, move the cursor one step upwards
  """
  def move_up(model) do
    model
    |> Text.line_size(model.cursor.y - 1)
    |> case do
      {:error, reason} ->
        Logger.debug("Cannot move up due to: #{reason}")
        model

      {:ok, lsize} ->
        cond do
          model.cursor.y != 0 ->
            cond do
              lsize >= model.cursor.x ->
                put_in(model.cursor, %{model.cursor | y: model.cursor.y - 1})

              lsize < model.cursor.x ->
                put_in(model.cursor, %{model.cursor | x: lsize, y: model.cursor.y - 1})
            end

          true ->
            model
        end
    end
  end

  @doc """
  If possible, move the cursor one step downwards
  """
  def move_down(model) do
    model
    |> Text.line_size(model.cursor.y + 1)
    |> case do
      {:error, reason} ->
        Logger.debug("Cannot move up due to: #{reason}")
        model

      {:ok, lsize} ->
        cond do
          can_move_down?(model) ->
            cond do
              lsize >= model.cursor.x ->
                put_in(model.cursor, %{model.cursor | y: model.cursor.y + 1})

              lsize < model.cursor.x ->
                put_in(model.cursor, %{model.cursor | x: lsize, y: model.cursor.y + 1})
            end

          true ->
            model
        end
    end
  end

  @doc """
  Move the cursor to the beginning of the line
  """
  def carriage_return(model), do: put_in(model.cursor, %{model.cursor | x: 0})

  @doc """
  If possible, move the cursor to the end of the line
  """
  def goto_end(model) do
    model
    |> Text.line_size(model.cursor.y)
    |> case do
      {:error, reason} ->
        Logger.debug("Cannot move up due to: #{reason}")
        model

      {:ok, lsize} ->
        put_in(model.cursor, %{model.cursor | x: lsize})
    end
  end
end

defmodule Chaffinch.App.State do
  @moduledoc """
  Module for other state modulations.
  """

  alias Chaffinch.App.{Text, Cursor}

  @doc """
  Increment the dirtyness of the editor state
  """
  def make_dirty(model), do: %{model | dirty: model.dirty + 1} |> update_status_msg()

  def is_dirty?(model) when model.dirty != 0, do: true
  def is_dirty?(_other), do: false

  def is_editable?(model) when model.active_view == :text, do: true
  def is_editable?(_other), do: false

  @doc """
  Update the status with either filename and the state (dirty/clean) or an error message
  """
  def update_status_msg(model, errormsg \\ nil) do
    cond do
      errormsg != nil ->
        %{model | status_msg: {:error, errormsg}}

      true ->
        %{model | status_msg: _build_status_message(model)}
    end
  end

  @doc """
  Set the active view to the `quitting in a dirty state` prompt if the state is in face dirty
  """
  def process_quit_command(model) do
    cond do
      model.active_view == :text and is_dirty?(model) ->
        Cursor.hide_cursor()
        %{model | active_view: :quit}

      true ->
        quit()
    end
  end

  @doc """
  Save the current state of the document with or without saving depending on the active view
  """
  def process_save_command(model) do
    case model.active_view do
      :text -> Text.save_text(model)
      :quit -> quit()
    end
  end

  @doc """
  Return to the text from another view
  """
  def return_to_text(model) do
    Cursor.show_cursor()
    %{model | active_view: :text}
  end

  defp _build_status_message(model) do
    pos_string = " | Line #{model.cursor.y + 1} | Column #{model.cursor.x + 1}"

    cond do
      model.fileinfo != nil ->
        cond do
          is_dirty?(model) ->
            {:ok, "File: " <> model.fileinfo.filename <> "*" <> pos_string}

          true ->
            {:ok, "File: " <> model.fileinfo.filename <> pos_string}
        end

      true ->
        {:ok, "No File" <> pos_string}
    end
  end

  @doc """
  Ungracefully quit and just reset the console
  """
  def quit() do
    System.cmd("reset", [])
    System.halt()
  end

  @doc """
  Update model to reflect new window size
  """
  def resize_window(model, %{h: height, w: width}) do
    %{model | window: %{height: height, width: width}}
    |> sync_view()
  end

  @doc """
  Sync the global offset of text and cursor when moving outside of the window
  """
  def sync_view(model) do
    padding = length(Integer.digits(length(model.textrows))) + 1

    offset_y = model.cursor.y + model.deadspace.t + model.deadspace.b - model.window.height

    offset_x =
      model.cursor.x + model.deadspace.l + model.deadspace.p +
        model.deadspace.r - model.window.width

    offset_y = if offset_y > 0, do: offset_y, else: 0
    offset_x = if offset_x > 0, do: offset_x, else: 0

    %{model | offset_y: offset_y, offset_x: offset_x, deadspace: %{model.deadspace | p: padding}}
    |> Cursor.sync_cursor()
  end
end
