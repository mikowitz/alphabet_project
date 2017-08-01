defmodule DynamicsGenerator.V1 do
  @polyrhythm_generator PolyrhythmGenerator.V5

  def raw_part(letter, pulse) do
    @polyrhythm_generator.raw_letter_part(letter, pulse)
  end

  def processed_part(letter, pulse) do
    @polyrhythm_generator.processed_letter_part(letter, pulse)
  end

  def dynamic_determining_boundaries do
  end

  def measures(letter, pulse) do
    processed_part(letter, pulse)
    |> Enum.with_index
    |> Enum.map(fn {{tuplet, events = [first_event | rest_events]}, i} ->
      measure = %Measure{tuplet: tuplet, events: events}
      density = Measure.density(measure)
      new_events = [first_event <> dynamic_for_float(density, i) | rest_events]
      {tuplet, new_events}
    end)
  end

  def dynamic_for_float(density, measure_index) do
    envelope = cond do
      measure_index <= 20 -> ["ppp", "ppp", "ppp", "ppp", "ppp", "ppp", "ppp", "ppp"]
      measure_index <= 40 -> ["ppp", "ppp", "ppp", "pp", "pp", "pp", "p", "p"]
      measure_index <= 60 -> ["ppp", "pp", "pp", "p", "p", "p", "mp", "mp"]
      measure_index <= 80 -> ["ppp", "pp", "p", "p", "mp", "mp", "mp", "mf"]
      measure_index <= 100 -> ["ppp", "pp", "p", "p", "mp", "mf", "mf", "f"]
      measure_index <= 120 -> ["ppp", "pp", "p", "mp", "mp", "mf", "f", "ff"]
      measure_index <= 140 -> ["ppp", "pp", "p", "mp", "mf", "f", "ff", "fff"]
      measure_index <= 160 -> ["ppp", "pp", "p", "mp", "mf", "f", "f", "ff"]
      measure_index <= 180 -> ["ppp", "pp", "p", "mp", "mf", "mf", "f", "f"]
      true -> ["ppp", "ppp", "pp", "p", "mp", "mf", "mf", "f"]
    end
    _to_dynamic(density, envelope)
  end

  def _to_dynamic(density, dynamic_envelope) do
    with [d1, d2, d3, d4, d5, d6, d7, d8] <- dynamic_envelope do
      cond do
        density == 0 -> ""
        density > 1 -> "\\" <> d1
        density >= 0.75 -> "\\" <> d2
        density >= 0.6666 -> "\\" <> d3
        density >= 0.5 -> "\\" <> d4
        density >= 0.3333 -> "\\" <> d5
        density >= 0.25 -> "\\" <> d6
        density >= 0.1 -> "\\" <> d7
        true -> "\\" <> d8
      end
    end
  end
end
