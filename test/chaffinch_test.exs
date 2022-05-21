defmodule ChaffinchTest do
  use ExUnit.Case
  doctest Chaffinch

  @test_state %EditorState{
    textrows: [%EditorText{}],
    cursor: %EditorCursor{x: 0, y: 0}
  }

  test "get line size oob" do
    assert {:error, :ioob} == Text.line_size(@test_state, -1)
  end

  test "try move oob" do
    assert @test_state == Cursor.move_left(@test_state)
  end
end
