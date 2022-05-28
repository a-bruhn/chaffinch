defmodule Chaffinch do
  @moduledoc """
  Define the supervision tree for the application
  """

  use Application

  def start(_type, _args) do
    children = [
      {Ratatouille.Runtime.Supervisor, runtime: [app: Chaffinch.App]}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: Chaffinch.Supervisor
    )
  end

  def stop(_) do
    System.halt()
  end
end
