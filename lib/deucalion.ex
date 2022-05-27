defmodule Deucalion do
  @moduledoc """
  Documentation for `Deucalion`.

  https://github.com/Showmax/prometheus-docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-details
  """

  import NimbleParsec

  alias Deucalion.{TypeLine, HelpLine, CommentLine, Sample}

  docstring =
    utf8_string([], min: 1)
    |> unwrap_and_tag(:docstring)

  label = ascii_string([?a..?z, ?_], min: 1)

  help_body =
    string("HELP")
    |> unwrap_and_tag(:comment_type)
    |> ignore(string(" "))
    |> concat(label |> unwrap_and_tag(:metric_name))
    |> ignore(string(" "))
    |> concat(docstring)

  type_body =
    string("TYPE")
    |> unwrap_and_tag(:comment_type)
    |> ignore(string(" "))
    |> concat(label |> unwrap_and_tag(:metric_name))
    |> ignore(string(" "))
    |> concat(
      choice([
        string("counter"),
        string("gauge")
      ])
      |> unwrap_and_tag(:metric_type)
    )

  comment_body =
    utf8_string([], min: 1)
    |> unwrap_and_tag(:comment)

  comment =
    ignore(string("# "))
    |> choice([
      type_body,
      help_body,
      comment_body
    ])

  timestamp = ignore(string(" ")) |> utf8_string([?0..?9], min: 1) |> tag(:timestamp)

  key_value_pair =
    label
    |> tag(:key)
    |> ignore(string("="))
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)
    |> tag(:value_yeah)

  key_value_pairs =
    ignore(string("{"))
    |> times(
      key_value_pair
      |> ignore(optional(string(",")))
      |> ignore(optional(string(" "))),
      min: 0
    )
    |> ignore(string("}"))

  sample =
    label
    |> tag(:label)
    |> optional(key_value_pairs)
    |> ignore(string(" "))
    |> ascii_string([?0..?9], min: 1)
    |> tag(:value)
    |> optional(timestamp)

  defparsecp(
    :parse,
    choice([
      sample,
      comment
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
      {:ok, value, _, _, _, _} ->
        cast(value)
    end
  end

  defp cast([{:comment_type, "TYPE"} | opts]) do
    struct!(%TypeLine{}, opts)
  end

  defp cast([{:comment_type, "HELP"} | opts]) do
    struct!(%HelpLine{}, opts)
  end

  defp cast(comment: comment) do
    %CommentLine{comment: comment}
  end

  defp cast(value: [{:label, [metric_name]}, value]) do
    %Sample{metric_name: metric_name, value: value}
  end

  defp cast(value: [{:label, [metric_name]}, value], timestamp: [timestamp]) do
    %Sample{metric_name: metric_name, value: value, timestamp: timestamp}
  end
end
