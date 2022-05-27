defmodule DeucalionTest do
  use ExUnit.Case
  doctest Deucalion

  alias Deucalion.{HelpLine, TypeLine, CommentLine, Sample}

  test "parses a help line" do
    line = ~s(# HELP http_requests_total The total number of HTTP requests.)

    assert Deucalion.parse_line(line) == %HelpLine{
             metric_name: "http_requests_total",
             docstring: "The total number of HTTP requests."
           }
  end

  test "parses a type line" do
    line = ~s(# TYPE http_requests_total counter)

    assert Deucalion.parse_line(line) == %TypeLine{
             metric_name: "http_requests_total",
             metric_type: "counter"
           }
  end

  test "parses a comment" do
    line = ~s(# I am a comment)

    assert Deucalion.parse_line(line) == %CommentLine{
             comment: "I am a comment"
           }
  end

  describe "Samples" do
    test "minimalistic line" do
      line = ~s(metric_without_timestamp_and_labels 12.47)

      assert Deucalion.parse_line(line) == %Sample{
               metric_name: "metric_without_timestamp_and_labels",
               value: "12.47"
             }
    end

    test "sample with timestamp" do
      line = ~s(http_requests_total 1027 1395066363000)

      assert Deucalion.parse_line(line) == %Sample{
               metric_name: "http_requests_total",
               value: "1027",
               timestamp: 1_395_066_363_000
             }
    end

    test "sample with label" do
      line = ~s(http_requests_total{method="post",code="200"} 1027 1395066363000)

      assert Deucalion.parse_line(line) == %Sample{
               metric_name: "http_requests_total",
               value: "1027",
               timestamp: 1_395_066_363_000,
               labels: [{"method", "post"}, {"code", "200"}]
             }
    end
  end
end
