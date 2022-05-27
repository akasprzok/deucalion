defmodule Deucalion do
  @moduledoc """
  Documentation for `Deucalion`.

  https://github.com/Showmax/prometheus-docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-details
  """

  import NimbleParsec

  alias Deucalion.{TypeLine, HelpLine, CommentLine, Sample}

  docstring =
    utf8_string([], min: 1)
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

  type_body =
    string("TYPE")
    |> tag(:type)
    |> ignore(string(" "))
    |> concat(label)
    |> ignore(string(" "))
    |> choice([
      string("counter"),
      string("gauge")
    ])
    |> tag(:type)

  comment_body =
    utf8_string([], min: 1)
    |> tag(:comment_body)

  sample =
    label
    |> tag(:label)
    |> ignore(string(" "))
    |> ascii_string([?0..?9], min: 1)
    |> tag(:value)

  timestamp = ignore(string(" ")) |> ascii_string([?0..?9], min: 1) |> tag(:timestamp)

  defparsec(
    :parse,
    choice([
      comment |> concat(help_body),
      comment |> concat(type_body),
      comment |> concat(comment_body),
      sample,
      sample |> concat(timestamp)
    ])
  )

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

  def parse_line(line) do
    line
    |> parse()
    |> to_line()
  end

  defp to_line(line) do
    line
    |> case do
      {:ok, [comment: ["#"], type: [{:type, ["TYPE"]}, metric_name, metric_type]], _, _, _, _} ->
        %TypeLine{metric_name: metric_name, metric_type: metric_type}

      {:ok, [comment: ["#"], label: [{:help, ["HELP"]}, metric_name], docstring: [docstring]], _,
       _, _, _} ->
        %HelpLine{metric_name: metric_name, docstring: docstring}

      {:ok, [comment: ["#"], comment_body: [comment]], _, _, _, _} ->
        %CommentLine{comment: comment}

      {:ok, [value: [{:label, [metric_name]}, value]], _, _, _, _} ->
        %Sample{metric_name: metric_name, value: value}
    end
  end
end
