defmodule DeucalionTest do
  use ExUnit.Case
  doctest Deucalion

  alias Deucalion.{Exposition, MetricFamily, Metric}

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
end
