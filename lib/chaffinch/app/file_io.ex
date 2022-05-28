defmodule(Chaffinch.App.FileIO) do
  @moduledoc """
  Import and save data
  """
  require Logger

  alias Chaffinch.App.TextData

  def import_file(path) do
    case File.read(path) do
      {:error, reason} ->
        Logger.error("Cannot import file due to: #{reason}")
        {:error, :ioe}

      {:ok, file} ->
        textrows =
          String.split(file, "\n")
          |> Enum.map(fn x -> %TextData{text: x} end)

        {:ok, textrows}
    end
  end

  def write_file(data, path) do
    case File.open(path, [:write]) do
      {:error, reason} ->
        Logger.error("Cannot import file due to: #{reason}")
        {:error, :ioe}

      {:ok, file} ->
        IO.binwrite(file, data)
        File.close(file)
        {:ok, path}
    end
  end
end
