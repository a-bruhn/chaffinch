defmodule Chaffinch.App.View do
  @moduledoc """
  Module holding views to be rendered in the application
  """

  import Ratatouille.Constants, only: [color: 1]
  import Ratatouille.View

  @app_title "Chaffinch Text Editor"

  def render_active_view(model) do
    b_bar =
      bar do
        label(content: "Quit: CTRL-Q | Save: CTRL-S")
      end

    t_bar =
      bar do
        case model.status_msg do
          {:ok, message} ->
            label(content: message)

          {:error, message} ->
            label(content: "! " <> message, color: color(:red))
        end
      end

    view bottom_bar: b_bar, top_bar: t_bar do
      panel(title: @app_title, height: :fill) do
        case model.active_view do
          :text -> _render_text(model)
          :quit -> _render_quit_prompt()
          _ -> _render_text(model)
        end
      end
    end
  end

  defp _render_text(model) do
    for {textrow, idx} <- Enum.with_index(model.textrows) do
      label(content: "#{idx + 1} #{textrow |> Map.get(:text)}")
    end
  end

  defp _render_quit_prompt() do
    label(
      content: "Text has unsaved changes. Press:",
      color: color(:blue)
    )

    label(
      content: "    CTRL-S to save and quit",
      color: color(:blue)
    )

    label(
      content: "    CTRL-Q to close anyway",
      color: color(:blue)
    )
  end
end
