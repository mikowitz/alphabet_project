defmodule DynamicsGenerator.V1 do
  @dynamics ~w(\\ppp \\pp \\p \\mp \\mf \\f \\ff \\fff)
  @polyrhythm_generator PolyrhythmGenerator.V5

  def raw_part(letter, pulse) do
    @polyrhythm_generator.raw_letter_part(letter, pulse)
  end

  def processed_part(letter, pulse) do
    @polyrhythm_generator.processed_letter_part(letter, pulse)
  end

  def dynamic_index(dynamic) do
    Enum.find_index(@dynamics, &(&1 == dynamic))
  end

  def measures(raw_measures) do
    raw_measures
    |> Enum.with_index
    |> Enum.map(fn {measure, i} ->
      density = Measure.density(measure)
      %Measure{measure | dynamic: dynamic_for_float(density, i)}
    end)
    |> clean_dynamics()
    |> add_hairpins()
  end

  def add_hairpins(measures = [m|_]), do: _add_hairpins(measures, m.dynamic, [])

  defp _add_hairpins(l, _, acc) when length(l) <= 1, do: Enum.reverse(l ++ acc)
  defp _add_hairpins([m,m2|ms], current_dynamic, acc) do
    next_dynamic = case m2.dynamic do
      nil -> current_dynamic
      d -> d
    end
    either_measure_all_rests = Measure.all_rests?(m) || Measure.all_rests?(m2)
    new_m = cond do
      m2.dynamic == nil -> m
      dynamic_index(m2.dynamic) < dynamic_index(current_dynamic) && not either_measure_all_rests ->
        %Measure{m | hairpin: ">" }
      dynamic_index(m2.dynamic) > dynamic_index(current_dynamic) && not either_measure_all_rests ->
        %Measure{m | hairpin: "<" }
      true -> m
    end
    _add_hairpins([m2|ms], next_dynamic, [new_m|acc])
  end

  def clean_dynamics(measures = [m|_]) do
    new_measures = Enum.chunk_every(measures, 2, 1, :discard)
    |> Enum.map(fn [m1, m2] ->
         case m1.dynamic == m2.dynamic do
           true -> %Measure{ m2 | dynamic: nil }
           false -> m2
         end
    end)
    [m|new_measures]
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
