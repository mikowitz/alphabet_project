defmodule Measure do
  defstruct [
    :time_signature, :tuplet, :events,
    :dynamic, :phoneme
  ]

  def density(%__MODULE__{tuplet: nil}), do: 1.0
  def density(%__MODULE__{tuplet: {0, _}}), do: 0.0
  def density(%__MODULE__{tuplet: {n, d}, events: events}) do
    Enum.count(events, fn e -> e == "c8" end) / n
  end

  def to_lily(%__MODULE__{time_signature: {n, d}, events: events}) do
    "  \\time #{n}/#{d} #{Enum.join(events, " ")}"
  end
  def to_lily(%__MODULE__{tuplet: {n, d}, events: events}) do
    "  \\tuplet #{n}/#{d} { #{Enum.join(events, " ")} }"
  end
end
