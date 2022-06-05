defmodule Deucalion do
  @moduledoc """
  Deucalion is a parser for the Prometheus metric format.

  Based primarily on these sources:
  https://github.com/Showmax/prometheus-docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-details
  https://prometheus.io/docs/concepts/data_model/#metric-names-and-labels
  """

  import NimbleParsec

  alias Deucalion.MetricFamily

  whitespace = optional(ignore(ascii_string([32, ?\t], min: 1)))

  help =
    utf8_string([], min: 1)
    |> unwrap_and_tag(:help)

  name =
    ascii_string([?a..?z, ?A..?Z, ?_, ?:], max: 1)
    |> ascii_string([?a..?z, ?A..?Z, ?_, ?:], min: 0)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:name)

  help_body =
    string("HELP")
    |> unwrap_and_tag(:comment_type)
    |> concat(whitespace)
    |> concat(name)
    |> concat(whitespace)
    |> concat(help)

  type_body =
    string("TYPE")
    |> unwrap_and_tag(:comment_type)
    |> concat(whitespace)
    |> concat(name)
    |> concat(whitespace)
    |> concat(
      choice([
        string("counter"),
        string("gauge"),
        string("histogram"),
        string("summary"),
        string("untyped")
      ])
      |> map({Deucalion.MetricType, :parse, []})
      |> unwrap_and_tag(:type)
    )

  comment_body =
    utf8_string([], min: 1)
    |> unwrap_and_tag(:comment)

  comment =
    whitespace
    |> ignore(string("# "))
    |> choice([
      type_body,
      help_body,
      comment_body
    ])

  timestamp = ignore(string(" ")) |> integer(min: 1) |> unwrap_and_tag(:timestamp)

  label_name =
    ascii_string([?a..?z, ?A..?Z, ?_], max: 1)
    |> ascii_string([?a..?z, ?A..?Z, ?_], min: 0)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:name)

  label_value =
    ignore(string("\""))
    |> repeat_while(
      choice([
        ~S(\") |> string() |> replace(?"),
        utf8_char([])
      ]),
      {:not_quote, []}
    )
    |> ignore(string("\""))
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:value)

  label =
    label_name
    |> ignore(string("="))
    |> concat(label_value)
    |> reduce(:label_to_map)

  labels =
    ignore(string("{"))
    |> concat(
      repeat(
        label
        |> ignore(optional(string(",")))
        |> concat(whitespace)
      )
    )
    |> ignore(string("}"))
    |> reduce(:labels_to_map)
    |> unwrap_and_tag(:labels)

  value =
    choice([
      ascii_string([?0..?9, ?., ?e], min: 1),
      string("+Inf"),
      string("-Inf"),
      string("Nan")
    ])
    |> map({Deucalion.Value, :parse, []})
    |> unwrap_and_tag(:value)

  sample =
    whitespace
    |> concat(name)
    |> optional(labels)
    |> concat(whitespace)
    |> concat(value)
    |> optional(timestamp)

  defparsecp(
    :parse,
    choice([
      sample,
      comment,
      whitespace
    ])
  )

  def parse_file(path) do
    path
    |> File.read!()
    |> parse_text()
  end

  defp labels_to_map(labels) do
    labels
    |> Enum.reduce(%{}, fn label, acc -> Map.merge(acc, label) end)
  end

  defp label_to_map(name: label, value: value) do
    %{label => value}
  end

  def parse_text(body) do
    body
    |> String.split("\n")
    |> Enum.reduce(%{}, &parse_line/2)
    |> Map.values()
    |> maybe_unwrap()
  end

  defp maybe_unwrap([metric_family]), do: metric_family
  defp maybe_unwrap(metric_families), do: metric_families

  defp parse_line(line, exposition) do
    line
    |> parse()
    |> case do
      {:ok, tokens, "", _context, _position, _byte_offset} ->
        tokens |> MetricFamily.from_tokens() |> do_reduce(exposition)
        # {:ok, tokens, remainder, _context, _position, _byte_offset} ->
        # {:error, reason, remainder, context, position, byte_offset}
    end
  end

  defp do_reduce(%MetricFamily{} = metric_family, exposition) do
    Map.update(exposition, metric_family.name, metric_family, fn existing_value ->
      MetricFamily.merge(existing_value, metric_family)
    end)
  end

  defp do_reduce(nil, exposition), do: exposition

  defp not_quote(<<?", _::binary>>, context, _, _), do: {:halt, context}
  defp not_quote(_, context, _, _), do: {:cont, context}
end
