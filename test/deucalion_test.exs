defmodule DeucalionTest do
  use ExUnit.Case, async: true
  doctest Deucalion

  alias Deucalion.{Metric, MetricFamily}

  test "parses a help line" do
    text = ~S(# HELP http_requests_total The total number of HTTP requests.
    # TYPE http_requests_total counter
    http_requests_total{method="post",code="200"} 1027 1395066363000
    http_requests_total{method="post",code="400"}    3 1395066363000
    )

    assert Deucalion.parse_text(text) ==
             %MetricFamily{
               name: "http_requests_total",
               type: :counter,
               help: "The total number of HTTP requests.",
               metrics: %{
                 %{"method" => "post", "code" => "200"} => %Metric{
                   value: 1027.0,
                   timestamp: 1_395_066_363_000
                 },
                 %{"method" => "post", "code" => "400"} => %Metric{
                   value: 3.0,
                   timestamp: 1_395_066_363_000
                 }
               }
             }
  end

  test "wat" do
    text = ~S(# Escaping in label values
    msdos_file_access_time_seconds{path="C:\\DIR\\FILE.TXT",error="Cannot find file:\n\"FILE.TXT\""} 1.458255915e9
    )

    assert Deucalion.parse_text(text) ==
             %MetricFamily{
               name: "msdos_file_access_time_seconds",
               type: :untyped,
               help: nil,
               metrics: %{
                 %{
                   "path" => "C:\\\\DIR\\\\FILE.TXT",
                   "error" => "Cannot find file:\\n\"FILE.TXT\""
                 } => %Metric{value: 1_458_255_915.0, timestamp: nil}
               }
             }
  end
end
