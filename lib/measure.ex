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

  def all_rests?(%__MODULE__{events: events}) do
    Enum.all?(events, &(&1 == "r8"))
  end

  def to_lily(measure = %__MODULE__{time_signature: {n, d}}) do
    case all_rests?(measure) do
      true  -> "  \\time #{n}/#{d} R8 * #{n}"
      false -> "  \\time #{n}/#{d} #{events_to_lily(measure)}"
    end
  end
  def to_lily(measure = %__MODULE__{tuplet: {n, d}}) do
    case all_rests?(measure) do
      true  -> "  R8 * #{d}"
      false -> "  \\tuplet #{n}/#{d} { #{events_to_lily(measure)} }"
    end
  end

  def events_to_lily(measure = %__MODULE__{events: events}) do
    with  [h|t] <- reduce(events),
          h <- h <> dynamic_markup(measure) <> phoneme_markup(measure)
    do
      [h|t] |> add_beaming() |> Enum.join(" ")
    end
  end

  def add_beaming(events) do
    case Enum.all?(events, &String.ends_with?(&1, "8")) do
      true -> events |> List.insert_at(1, "[") |> List.insert_at(-1, "]")
      false -> events
    end
  end

  def phoneme_markup(%__MODULE__{phoneme: nil}), do: ""
  def phoneme_markup(%__MODULE__{phoneme: phoneme}) do
    ~s(^\\markup "[#{phoneme}]")
  end

  def dynamic_markup(%__MODULE__{dynamic: nil}), do: ""
  def dynamic_markup(%__MODULE__{dynamic: dynamic}), do: dynamic

  def reduce(events), do: reduce(events, [])
  def reduce([], acc), do: Enum.reverse(acc)
  def reduce(["r8", "r8" | t], acc) do
    reduce(t, ["r4" | acc])
  end
  def reduce([n, "r8" | t], acc) do
    with n <- Regex.replace(~r/8/, n, "4") do
      reduce(t, [n | acc])
    end
  end
  def reduce([h|t], acc) do
    reduce(t, [h|acc])
  end
end
