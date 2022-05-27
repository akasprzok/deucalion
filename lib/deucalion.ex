defmodule Deucalion do
  @moduledoc """
  Documentation for `Deucalion`.

  https://github.com/Showmax/prometheus-docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-details
  """

  import NimbleParsec

  docstring = utf8_string([], min: 1)
  |> tag(:docstring)

  label = ascii_string([?a..?z] ++ [?_], min: 1)

  help_body =
    string("HELP")
    |> tag(:help)
    |> ignore(string(" "))
    |> concat(label)
    |> tag(:label)
    |> ignore(string(" "))
    |> concat(docstring)

  comment =
    string("#")
    |> tag(:comment)
    |> ignore(string(" "))

  type_body = string("TYPE")
  |> tag(:type) |> ignore(string(" "))
  |> concat(label)
  |> ignore(string(" "))
  |> choice([
    string("counter"),
    string("gauge")
  ])
  |> tag(:type)


  defparsec(:parse_line,
  choice([
    comment |> concat(help_body),
    comment |> concat(type_body)
  ]))

  def parse_file(path) do
    path
    |> File.read!()
    |> parse_body()
  end

  def parse_body(body) do
    body
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
  end

  @doc """
  Hello world.

  ## Examples

      iex> Deucalion.hello()
      :world

  """
  def hello do
    :world
  end
end
