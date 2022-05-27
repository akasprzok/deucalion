defmodule Deucalion do
  @moduledoc """
  Documentation for `Deucalion`.

  https://github.com/Showmax/prometheus-docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-details
  """

  import NimbleParsec

  alias Deucalion.{TypeLine, HelpLine, CommentLine, Sample}

  leading_whitespace = optional(ignore(ascii_string([32, ?\t], min: 1)))

  docstring =
    utf8_string([], min: 1)
    |> unwrap_and_tag(:docstring)

  # https://prometheus.io/docs/concepts/data_model/#metric-names-and-labels
  metric_name =
    ascii_string([?a..?z, ?A..?Z, ?_, ?:], max: 1)
    |> ascii_string([?a..?z, ?A..?Z, ?_, ?:], min: 0)
    |> tag(:metric_name)

  help_body =
    string("HELP")
    |> unwrap_and_tag(:comment_type)
    |> ignore(string(" "))
    |> concat(metric_name)
    |> ignore(string(" "))
    |> concat(docstring)

  type_body =
    string("TYPE")
    |> unwrap_and_tag(:comment_type)
    |> ignore(string(" "))
    |> concat(metric_name)
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
    leading_whitespace
    |> ignore(string("# "))
    |> choice([
      type_body,
      help_body,
      comment_body
    ])

  timestamp = ignore(string(" ")) |> utf8_string([?0..?9], min: 1) |> unwrap_and_tag(:timestamp)

  label_name =
    ascii_string([?a..?z, ?A..?Z, ?_], max: 1)
    |> ascii_string([?a..?z, ?A..?Z, ?_], min: 0)
    |> tag(:name)

  label_value =
    optional(
      ignore(string("\""))
      |> ascii_string([32, ?a..?z, ?A..?Z, ?0..?9, ?-, ?_, ?...?:, ?\\, ?\n] |> IO.inspect(),
        min: 1
      )
      |> ignore(string("\""))
      |> unwrap_and_tag(:value)
    )

  label =
    label_name
    |> ignore(string("="))
    |> concat(label_value)
    |> tag(:label)

  labels =
    ignore(string("{"))
    |> concat(
      repeat(
        label
        |> ignore(optional(string(",")))
        |> ignore(optional(string(" ")))
      )
    )
    |> ignore(string("}"))
    |> tag(:labels)

  value =
    choice([
      ascii_string([?0..?9, ?., ?e], min: 1),
      string("+Inf"),
      string("-Inf"),
      string("Nan")
    ])
    |> unwrap_and_tag(:value)

  sample =
    leading_whitespace
    |> concat(metric_name)
    |> optional(labels)
    |> ignore(string(" "))
    |> concat(value)
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
    opts =
      opts
      |> Keyword.update(:metric_name, nil, &format_metric_name/1)

    struct!(%TypeLine{}, opts)
  end

  defp cast([{:comment_type, "HELP"} | opts]) do
    opts =
      opts
      |> Keyword.update(:metric_name, nil, &format_metric_name/1)

    struct!(%HelpLine{}, opts)
  end

  defp cast(comment: comment) do
    %CommentLine{comment: comment}
  end

  defp cast([{:metric_name, _} | _] = opts) do
    opts =
      opts
      |> Keyword.update(:timestamp, nil, &format_timestamp/1)
      |> Keyword.update(:metric_name, nil, &format_metric_name/1)
      |> Keyword.update(:labels, [], &format_labels/1)

    struct!(%Sample{}, opts)
  end

  defp format_timestamp(timestamp) do
    timestamp |> String.to_integer()
  end

  defp format_metric_name(metric_name) do
    metric_name |> IO.iodata_to_binary()
  end

  defp format_labels(labels) do
    Enum.map(labels, fn {:label, [name: name, value: value]} ->
      {name |> IO.iodata_to_binary(), value}
    end)
  end
end
