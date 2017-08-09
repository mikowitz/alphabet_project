defmodule Measure do
  defstruct [
    :time_signature, :tuplet, :events,
    :dynamic, :phoneme, :written_duration,
    :eigth_notes_per_duration, :hairpin
  ]

  def density(%__MODULE__{tuplet: nil}), do: 1.0
  def density(%__MODULE__{tuplet: {0, _}}), do: 0.0
  def density(%__MODULE__{tuplet: {n, _}, events: events}) do
    Enum.count(events, fn e -> e == "c8" end) / n
  end

  def all_rests?(%__MODULE__{events: events}) do
    Enum.all?(events, &(&1 == "r8"))
  end

  def to_lily(measure = %__MODULE__{}) do
    measure |> set_proper_duration() |> _to_lily()
  end

  def _to_lily(measure = %__MODULE__{time_signature: {n, d}}) do
    case all_rests?(measure) do
      true  -> "  \\time #{n}/#{d} R8 * #{n}"
      false -> "  \\time #{n}/#{d} #{events_to_lily(measure)}"
    end
  end
  def _to_lily(measure = %__MODULE__{tuplet: {n, d}, eigth_notes_per_duration: e}) do
    case all_rests?(measure) do
      true  -> "  R8 * #{d}"
      false ->
        with ratio <- round(n * e) / d do
          case round(ratio) == ratio do
            true -> events_to_lily(measure)
            false ->
              "  \\once \\override TupletNumber #'text =\n" <>
              "    #(tuplet-number::non-default-fraction-with-notes #{n} \"#{measure.written_duration}\" #{d} \"8\")"
              <> "\n" <>
              "  \\tuplet #{round(n * e)}/#{d} { #{events_to_lily(measure)} }"
          end
        end
    end
  end

  def events_to_lily(measure = %__MODULE__{}) do
    reduce(measure) |> add_markup() |> Map.get(:events) |> Enum.join(" ")
  end

  def add_markup(measure) do
    with events <- Enum.with_index(measure.events) do
      non_rest_indices = Enum.filter(events, fn {e, _i} -> not Regex.match?(~r/^r/, e) end)
      |> Enum.map(fn {_e, i} -> i end)
      {first_index, last_index} = Enum.min_max(non_rest_indices)

      add_phoneme(measure, first_index)
      |> add_dynamics(first_index)
      |> add_beaming(first_index, last_index)
    end
  end

  def add_beaming(measure, first_index, last_index) do
    with events <- measure.events do
      new_events = case Enum.all?(events, &Regex.match?(~r/(8|16)\.?$/, &1)) do
        true -> events |> List.insert_at(last_index + 1, "]") |> List.insert_at(first_index + 1, "[")
        false -> events
      end
      %__MODULE__{ measure | events: new_events }
    end
  end

  def add_dynamics(measure, first_index) do
    events = List.replace_at(measure.events, first_index, Enum.at(measure.events, first_index) <> dynamic_markup(measure) <> hairpin_markup(measure))
    %__MODULE__{ measure | events: events }
  end

  def add_phoneme(measure, first_index) do
    events = List.replace_at(measure.events, first_index, Enum.at(measure.events, first_index) <> phoneme_markup(measure))
    %__MODULE__{ measure | events: events }
  end

  def hairpin_markup(%__MODULE__{hairpin: nil}), do: ""
  def hairpin_markup(%__MODULE__{hairpin: hairpin}), do: "\\#{hairpin}"

  def phoneme_markup(%__MODULE__{phoneme: nil}), do: ""
  def phoneme_markup(%__MODULE__{phoneme: phoneme}) do
    ~s(^\\markup "[#{phoneme}]")
  end

  def dynamic_markup(%__MODULE__{dynamic: nil}), do: ""
  def dynamic_markup(%__MODULE__{dynamic: dynamic}), do: dynamic

  def reduce(measure = %__MODULE__{events: _, tuplet: nil}), do: measure
  def reduce(measure = %__MODULE__{tuplet: {_, _}}) do
    new_events = Enum.map(measure.events, fn e ->
      Regex.replace(~r/\d+$/, e, measure.written_duration)
    end)
    %Measure{ measure | events: new_events }
  end

  def set_proper_duration(measure = %Measure{time_signature: {_, _}, tuplet: nil}) do
    %Measure{ measure | written_duration: "8" }
  end
  def set_proper_duration(measure = %Measure{tuplet: {n, d}}) when d / n <= 0.5 do
    %Measure{ measure | written_duration: "16", eigth_notes_per_duration: 0.5 }
  end
  def set_proper_duration(measure = %Measure{tuplet: {n, d}}) do
    with x <- round(d / n) do
      {x, duration} = case x do
        0 -> {x, "16"}
        1 -> {x, "8"}
        2 -> {x, "4"}
        3 -> {x, "4."}
        n when n in [4, 5] -> {4, "2"}
        6 -> {x, "2."}
        7 -> {x, "2.."}
        _ -> {8, "1"}
      end
      %Measure{ measure | written_duration: duration, eigth_notes_per_duration: x }
    end
  end
end
