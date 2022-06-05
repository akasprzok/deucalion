defmodule Deucalion do
  @moduledoc """
  Deucalion is a parser for the Prometheus metric format.

  Based primarily on these sources:
  https://github.com/Showmax/prometheus-docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-details
  https://prometheus.io/docs/concepts/data_model/#metric-names-and-labels
  """

  import NimbleParsec

  alias Deucalion.{MetricFamily, MetricType}

  leading_whitespace = optional(ignore(ascii_string([32, ?\t], min: 1)))

  help =
    utf8_string([], min: 1)
    |> unwrap_and_tag(:help)

  metric_name =
    ascii_string([?a..?z, ?A..?Z, ?_, ?:], max: 1)
    |> ascii_string([?a..?z, ?A..?Z, ?_, ?:], min: 0)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:metric_name)

  help_body =
    string("HELP")
    |> unwrap_and_tag(:comment_type)
    |> ignore(string(" "))
    |> concat(metric_name)
    |> ignore(string(" "))
    |> concat(help)

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
    |> parse_text()
  end

  def parse_text(body) do
    body
    |> String.split("\n")
    |> IO.inspect(label: "split")
    |> Enum.reduce(%{}, &parse_line/2)
  end

  defp parse_line(line, exposition) do
    line
    |> parse()
    |> case do
      {:ok, tokens, "", _context, _position, _byte_offset} ->
        do_reduce(tokens, exposition)
        # {:ok, tokens, remainder, _context, _position, _byte_offset} ->
        # {:error, reason, remainder, context, position, byte_offset}
    end
  end

  defp do_reduce([comment_type: "HELP", metric_name: metric_name, help: help], exposition) do
    Map.update(
      exposition,
      metric_name,
      %MetricFamily{
        name: metric_name,
        help: help
      },
      fn metric_family ->
        %{metric_family | help: help}
      end
    )
  end

  defp do_reduce(
         [comment_type: "TYPE", metric_name: metric_name, metric_type: metric_type],
         exposition
       ) do
    type = MetricType.parse(metric_type)

    Map.update(
      exposition,
      metric_name,
      %MetricFamily{
        name: metric_name,
        type: type
      },
      fn metric_family ->
        %{metric_family | type: type}
      end
    )
  end

  defp not_quote(<<?", _::binary>>, context, _, _), do: {:halt, context}
  defp not_quote(_, context, _, _), do: {:cont, context}
end
