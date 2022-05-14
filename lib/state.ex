# TODO: Resolve duplicate/unncessary function calls and restructure
#  Increase the overall amount of status handling
#  Add type specs
#  Separate concerns and use a single module to interact with the input/output layers

defmodule Text do
  @moduledoc """
  Operations on text stored within the row-wise list of text structs inside the model struct.
  """

  require Logger

  defp _insert_chars(row_text, chars, pos) do
  	String.split_at(row_text, pos)
	  |> Tuple.insert_at(1, chars)
	  |> Tuple.to_list
	  |> Enum.join
  end

  defp _remove_chars(row_text, start_idx, end_idx) do
    {part1, part2} = String.split_at(row_text, start_idx)
    {_, part2_new} = String.split_at(part2, end_idx - start_idx)

    [part1, part2_new] |> Enum.join
  end

  @doc """
  Merge two text rows at index `idx`
  """
  def merge_lines(model, idx) do
    row1 = model |> row_text(idx)
    row2 = model |> row_text(idx + 1)

    new_textrow = [row1, row2] |> Enum.join
    new_textrows_list = List.replace_at(model.textrows, idx, %EditorText{text: new_textrow})
                        |> List.delete_at(idx+1)

    put_in(model.textrows, new_textrows_list)

  end

  @doc """
  Split current row of text into two rows
  """
  def split_row(model) do

    [this_line | next_line] = String.split_at(row_text(model), model.cursor.x) |> Tuple.to_list

    model
    |> add_row(Enum.join(next_line))
    |> update_row(%EditorText{text: this_line})
    |> Cursor.move_right
    |> Cursor.sync_cursor
    |> State.make_dirty
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
      idx not in 0..length(model.textrows) - 1 -> {:error, :ioob}
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

    new_rowtext = model
                  |> row_text
                  |> _insert_chars(chars, model.cursor.x)

    model
    |> update_row(%{row(model) | text: new_rowtext})
    |> Cursor.move_right(true)
    |> Cursor.sync_cursor
    |> State.make_dirty
  end

  @doc """
  Forward remove a char at the current cursor position
  """  
  def fwd_remove_char(model) do

    current_row_text = model |> row_text

    model
    |> Cursor.pos_in_line
    |> case do
      {:error, reason} -> 
        Logger.error("Cannot forward delete char due to: #{reason}")
        model
      {:ok, :line_end} -> cond do
        Cursor.can_move_down?(model) ->
          model |>  merge_lines(model.cursor.y)
        true -> model
      end
      {:ok, _} -> 
        new_text = _remove_chars(current_row_text, model.cursor.x, model.cursor.x + 1)
        model |> 
        update_row(%EditorText{text: new_text})
    end |> Cursor.sync_cursor |> State.make_dirty
  end

  @doc """
  Backward remove a char at the current cursor position
  """  
  def bwd_remove_char(model) do

    current_row_text = model |> row_text

    model
    |> Cursor.pos_in_line
    |> case do
      {:error, reason} -> 
        Logger.error("Cannot forward delete char due to: #{reason}")
        model
      {:ok, :line_beginning} -> cond do
        model.cursor.y != 0->
          model |> Cursor.move_left |> merge_lines(model.cursor.y - 1)
        true -> model
      end
      {:ok, _} -> 
        new_text = _remove_chars(current_row_text, model.cursor.x - 1, model.cursor.x)
        model 
        |> update_row(%EditorText{text: new_text}) 
        |> Cursor.move_left
    end |> Cursor.sync_cursor |> State.make_dirty
  end

  @doc """
  Add a linebreak at the current cursor position
  """  
  def insert_linebreak(model) do

    model
    |> Cursor.pos_in_line
    |> case do
      {:error, reason} -> 
        Logger.error("Cannot insert line break due to: #{reason}")
        model
      {:ok, :line_end} -> model |> add_row |> Cursor.move_right
      {:ok, :in_line} -> model |> split_row
      {:ok, :line_beginning} -> model |>
        add_row("", model.cursor.y) |> Cursor.move_down
    end |> Cursor.sync_cursor |> State.make_dirty
  end

  @doc """
  Add an empty row after the current cursor y-position
  """    
  def add_row(model), do: put_in(
      model.textrows,
      List.insert_at(model.textrows, model.cursor.y + 1, %EditorText{})
    )

  @doc """
  Add a new row with text `new_row_text` after the current cursor y-position
  """   
  def add_row(model, new_row_text), do: put_in(
      model.textrows, 
      List.insert_at(model.textrows, model.cursor.y + 1, %EditorText{text: new_row_text})
    )

  @doc """
  Add a new row with text `new_row_text` at the y-index `idx`
  """ 
  def add_row(model, new_row_text, idx), do: put_in(
      model.textrows, 
      List.insert_at(model.textrows, idx, %EditorText{text: new_row_text})
    )

end

defmodule Cursor do
  @moduledoc """
  Operations on the cursor stored in the cursor struct inside the model struct.
  """

  require ExTermbox.Bindings
  require IO.ANSI.Sequence
  require Logger

  IO.ANSI.Sequence.defsequence(:_show_cursor, "?25", "h")
  IO.ANSI.Sequence.defsequence(:_hide_cursor, "?25", "l")

  def show_cursor, do: IO.puts _show_cursor()
  def hide_cursor, do: IO.puts _hide_cursor()

  @doc """
  Set the displayed cursor position to the position stored in the model
  """ 
  def sync_cursor(model) do
    ExTermbox.Bindings.set_cursor(
      model.cursor.x + model.cursor.offset_x,
      model.cursor.y + model.cursor.offset_y
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
    |> Text.line_size 
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
    end |> sync_cursor
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
        true -> model
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
          {:ok, :line_end} -> cond do 
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
  	      true -> model
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
  	     true -> model
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
      {:ok, lsize} -> put_in(model.cursor, %{model.cursor | x: lsize})
    end
  end

end

defmodule State do
  @moduledoc """
  Module for other state modulations.
  """

  @doc """
  Increment the dirtyness of the editor state
  """ 
  def make_dirty(model), do: %{model | dirty: model.dirty + 1}

end