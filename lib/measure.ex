defmodule Measure do
  defstruct [
    :time_signature, :tuplet, :events,
    :dynamic, :phoneme
  ]

  def density(%__MODULE__{tuplet: nil}), do: 1.0
  def density(%__MODULE__{tuplet: {0, _}}), do: 0.0
  def density(%__MODULE__{tuplet: {n, _}, events: events}) do
    Enum.count(events, fn e -> e == "c8" end) / n
  end

  def to_lily(measure = %__MODULE__{time_signature: {n, d}}) do
    "  \\time #{n}/#{d} #{events_to_lily(measure)}"
  end
  def to_lily(measure = %__MODULE__{tuplet: {n, d}}) do
    "  \\tuplet #{n}/#{d} { #{events_to_lily(measure)} }"
  end

  def events_to_lily(%Measure{events: events, phoneme: nil, dynamic: nil}) do
    events |> List.insert_at(1, "[") |> List.insert_at(-1, "]") |> Enum.join(" ")
  end
  def events_to_lily(%Measure{events: events, phoneme: phoneme, dynamic: nil}) do
    with [h|t] <- events do
      [h <> "^\\markup \"[#{phoneme}]\""| t]
      |> add_beaming() |> Enum.join(" ")
    end
  end
  def events_to_lily(%Measure{events: events, phoneme: nil, dynamic: dynamic}) do
    with [h|t] <- events do
      [h <> dynamic | t]
      |> add_beaming() |> Enum.join(" ")
    end
  end
  def events_to_lily(%Measure{events: events, phoneme: phoneme, dynamic: dynamic}) do
    with [h|t] <- events do
      [h <> dynamic <> "^\\markup \"[#{phoneme}]\"" | t]
      |> add_beaming() |> Enum.join(" ")
    end
  end

  def add_beaming(events) do
    events |> List.insert_at(1, "[") |> List.insert_at(-1, "]")
  end
end
