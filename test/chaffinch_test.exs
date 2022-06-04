defmodule ChaffinchStateTest do
  use ExUnit.Case
  doctest Chaffinch

  alias Chaffinch.App.{Text, Cursor, State, EditorState, TextData, CursorData}

  @test_state_empty %EditorState{
    cursor: %CursorData{x: 0, y: 0}
  }

  @test_state_unknown_view %EditorState{
    active_view: :this_view_does_not_exist
  }

  @test_state_two_lines %EditorState{
    textrows: [%TextData{text: "a"}, %TextData{text: "b"}]
  }

  @test_state_one_line %EditorState{
    textrows: [%TextData{text: "ab"}],
    cursor: %CursorData{x: 1, y: 0}
  }

  test "get line size oob" do
    assert {:error, :ioob} == Text.line_size(@test_state_empty, -1)
  end

  test "get_line_size empty line" do
    assert {:ok, 0} == Text.line_size(@test_state_empty, 0)
  end

  test "try move oob" do
    assert @test_state_empty == Cursor.move_left(@test_state_empty)
    assert @test_state_empty == Cursor.move_right(@test_state_empty)
    assert @test_state_empty == Cursor.move_up(@test_state_empty)
    assert @test_state_empty == Cursor.move_down(@test_state_empty)
    assert @test_state_empty == Cursor.carriage_return(@test_state_empty)
    assert @test_state_empty == Cursor.goto_end(@test_state_empty)
  end

  test "try delete empty" do
    assert @test_state_empty.textrows == Text.bwd_remove_char(@test_state_empty).textrows
    assert @test_state_empty.textrows == Text.fwd_remove_char(@test_state_empty).textrows
  end

  test "merge lines" do
    assert @test_state_one_line.textrows == Text.merge_lines(@test_state_two_lines, 0).textrows
  end

  test "split line" do
    assert @test_state_two_lines.textrows == Text.split_row(@test_state_one_line).textrows
  end

  test "insert char" do
    assert State.is_dirty?(Text.insert_char(@test_state_empty, "a"))
    assert List.first(Text.insert_char(@test_state_empty, "a").textrows).text == "a"
  end

  test "editability" do
    refute State.is_editable?(@test_state_unknown_view)
    assert State.is_editable?(%EditorState{})
  end

  test "save in unknown view" do
    catch_error(State.process_save_command(@test_state_unknown_view))
  end
end
