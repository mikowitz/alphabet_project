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

  def events_to_lily(measure = %__MODULE__{events: [h|t]}) do
    with h <- h <> dynamic_markup(measure) <> phoneme_markup(measure) do
      [h|t] |> add_beaming() |> Enum.join(" ")
    end
  end

  def add_beaming(events) do
    events |> List.insert_at(1, "[") |> List.insert_at(-1, "]")
  end

  def phoneme_markup(%__MODULE__{phoneme: nil}), do: ""
  def phoneme_markup(%__MODULE__{phoneme: phoneme}) do
    ~s(^\\markup "[#{phoneme}]")
  end

  def dynamic_markup(%__MODULE__{dynamic: nil}), do: ""
  def dynamic_markup(%__MODULE__{dynamic: dynamic}), do: dynamic
end
