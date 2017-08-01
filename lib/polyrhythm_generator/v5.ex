defmodule PolyrhythmGenerator.V5 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @pitches ~w( c g eqf btqf d fqs aqf bqf ctqs ef eqs ftqs atqf a cqs cs etqf e f fs af bf b bqs )
  @dynamics_generator DynamicsGenerator.V1
  @pitch_generator PitchGenerator.V2

  import PolyrhythmGenerator

  def pulse_part(letter) do
    part = letter |> raw_pulse_part
    |> Enum.map(fn {{n, d}, notes} ->
      %Measure{
        time_signature: {n, d}, tuplet: nil,
        events: notes
      }
    end)
  end

  def letter_part(letter, pulse) do
    least_frequent = case pulse do
      "z" -> "q"
      _ -> "z"
    end
    case letter do
      ^least_frequent -> least_frequent_part_to_lily(letter, pulse)
      _               -> letter_part_to_lily(letter, pulse)
    end
  end

  def raw_pulse_part(letter) do
    ordered_coordinates(letter)
    |> Enum.map(fn {_, c} ->
      {{c, 8}, Stream.cycle(["c8"]) |> Enum.take(c)}
    end)
  end

  def raw_letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse) |> Enum.into(%{})
    part_ratios(letter, pulse)
    |> Enum.map(fn {i, r} ->
      pulse_count = pulse_coords[i]
      c = round(r * pulse_count)
      c = case c == 0 do
        true -> 1
        false -> c
      end
      {{c, pulse_count}, Stream.cycle(["c8"]) |> Enum.take(c)}
    end)
  end

  def processed_letter_part(letter, pulse) do
    raw_part = raw_letter_part(letter, pulse)
    modulo_tuple = Map.get(converted_frequencies(), letter)
    process_part(raw_part, modulo_tuple)
  end

  def process_part(raw, modulo), do: _process_part(raw, modulo, 0, [])

  def _process_part([], _, _, processed), do: Enum.reverse(processed)
  def _process_part([raw|rest], modulo = {1, m}, index, processed) do
    with {tuplet, notes} <- raw do
      processed_measure = Enum.with_index(notes, index) |> Enum.map(fn {_, i} ->
        case rem(i, m) == 0 do
          true -> "c8"
          false -> "r8"
        end
      end)
      new_index = index + length(notes)
      _process_part(rest, modulo, new_index, [{tuplet, processed_measure}|processed])
    end
  end
  def _process_part([raw|rest], modulo = {n, m}, index, processed) do
    with {tuplet, notes} <- raw do
      processed_measure = Enum.with_index(notes, index) |> Enum.map(fn {_, i} ->
        case rem(i, m) == n do
          true -> "r8"
          false -> "c8"
        end
      end)
      new_index = index + length(notes)
      _process_part(rest, modulo, new_index, [{tuplet, processed_measure}|processed])
    end
  end

  def letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse) |> Enum.into(%{})
    music = part_ratios(letter, pulse)
    |> Enum.map(fn {i, r} ->
      pulse_count = pulse_coords[i]
      c = round(r * pulse_count)
      measure = %Measure{
        time_signature: nil, tuplet: {c, pulse_count},
        events: (Stream.cycle(["c8"]) |> Enum.take(c))
      }
      Measure.to_lily(measure)
    end) |> Enum.join("\n")
   write_lilypond_file(letter, music)
  end

  def pulse_ratios(letter) do
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_, y} -> y end)
    Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end)
  end

  def part_ratios(letter, pulse) do
    pulse = pulse_ratios(pulse)
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_, y} -> y end)
    pulse = Enum.into(pulse, %{})
    coords = Enum.into(Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end), %{})
    ratios = Enum.sort(Map.keys(coords))
    |> Enum.map(fn i ->
      {pn, pd} = pulse[i]
      {n, d} = coords[i]
      # multiply the fraction by the reciprocal of the pulse ratio so that the pulse always == 1
      {i, reduce(n * pd, d * pn)}
    end) |> Enum.map(fn {i, {x, y}} -> {i, x / y} end)
    letter_max = Enum.map(ratios, fn {_, r} -> r end) |> Enum.max
    letter_min = Enum.map(ratios, fn {_, r} -> r end) |> Enum.min
    # map the min/max to 1/16 <-> 2 and make sure every ratio is in that range
    Enum.map(ratios, fn {i, r} ->
      {i, __MODULE__.map(r, letter_min, letter_max, 1/16, 2)}
    end)
  end

  def reduce(a, b) do
    with g <- Integer.gcd(a, b) do
      {round(a / g), round(b / g)}
    end
  end

  def map(v, start_c, stop_c, start_t, stop_t) do
    start_t + (stop_t - start_t) * ((v - start_c) / (stop_c - start_c))
  end

  def converted_frequencies do
    frequencies() |> Enum.map(fn {letter, freq} ->
      cond do
        freq >= 1 -> {letter, {round(Float.ceil(freq) - 1), round(Float.ceil(freq))}}
        freq >= 0.5 -> {letter, {1, 3}}
        true -> {letter, {1, round(1 / freq)}}
      end
    end) |> Enum.into(%{})
  end

  def pulse_part_to_lily(letter) do
    modulation_map = phoneme_modulation_points(letter) |> Enum.into(Map.new)
    part = letter |> pulse_part
    |> Enum.with_index
    |> Enum.map(fn {{{n, d}, notes}, i} ->
      notes = case Map.get(modulation_map, i) do
        nil -> notes
        phoneme ->
          [note|ns] = notes
          [note <> "^\\markup \"[#{phoneme}]\""|ns]
      end
      "\\time #{n}/#{d} #{Enum.join(notes, " ")}"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, part)
    {:ok, letter}
  end

  def apply_row([], _row_index, acc), do: acc
  def apply_row([measure|measures], row_index, acc) do
    {{n, d}, notes} = measure
    {new_notes, next_index} = apply_row_to_measure(notes, row_index, [])
    apply_row(measures, next_index, acc ++ [{{n, d}, new_notes}])
  end

  def apply_row_to_measure([], index, acc), do: {acc, index}
  def apply_row_to_measure([n = << "r8", _ :: binary >>|ns], index, acc) do
    apply_row_to_measure(ns, index, acc ++ [n])
  end
  def apply_row_to_measure([n|ns], index, acc) do
    apply_row_to_measure(ns, index + 1,
     acc ++ [Regex.replace(~r/c/, n, Enum.at(@pitches, rem(index, length(@pitches))))])
  end

  def least_frequent_part_to_lily(letter, pulse) do
    modulation_map = phoneme_modulation_points(letter) |> Enum.into(Map.new)
    part = letter |> @dynamics_generator.measures(pulse)
    |> apply_row(0, [])
    |> Enum.with_index
    |> Enum.map(fn {{{n, d}, notes}, i} ->
      notes = case Map.get(modulation_map, i) do
        nil -> notes
        phoneme ->
          [note|ns] = notes
          [note <> "^\\markup \"[#{phoneme}]\""|ns]
      end
      %Measure{
        time_signature: nil, tuplet: {n, d},
        events: notes
      }
    end)
  end

  def letter_part_to_lily(letter, pulse) do
    {^letter, pitches} = Enum.find(measure_pitches(pulse), fn {l, _} ->
      l == letter
    end)
    modulation_map = phoneme_modulation_points(letter) |> Enum.into(Map.new)
    part = letter |> @dynamics_generator.measures(pulse)
    |> Enum.with_index |> Enum.map(fn {{{n, d}, notes}, i} ->
      pitch = Enum.at(pitches, i)
      notes = Enum.map(notes, fn n ->
        case n do
          "r8" -> "r8"
          note -> Regex.replace(~r/c/, note, pitch)
        end
      end)
      notes = case Map.get(modulation_map, i) do
        nil -> notes
        phoneme ->
          [note|ns] = notes
          [note <> "^\\markup \"[#{phoneme}]\""|ns]
      end
      %Measure{
        time_signature: nil, tuplet: {n, d},
        events: notes
      }
    end)
  end

  def measure_pitches(pulse) do
    @pitch_generator.generate_measure_pitches(pulse)
  end

  def consonant_phoneme_modulation_points(letter) do
    PolyrhythmGenerator.ordered_coordinates(letter)
    |> Enum.sort_by(fn {_, y} -> y end)
    |> Enum.with_index
    |> Enum.filter(fn {{x, _}, i} -> rem(i, 20) == 0 || x == 0 end)
    |> Enum.zip(Stream.cycle(["ei", "i:", "ai", "ou", "u:"]))
    |> Enum.map(fn {{{x, _}, _}, vowel} -> {x, vowel} end)
    |> Enum.sort
  end

  def vowel_phoneme_modulation_points(letter) do
    PolyrhythmGenerator.ordered_coordinates(letter)
    |> Enum.sort_by(fn {_, y} -> y end)
    |> Enum.with_index
    |> Enum.filter(fn {{x, _}, i} -> rem(i, 20) == 0 || x == 0 end)
    |> Enum.map(fn {{x, _}, _} -> x end)
    |> Enum.sort
    |> Enum.zip(Stream.cycle(Map.get(vowel_phoneme_pairs(), letter)))
  end

  def phoneme_modulation_points(letter) do
    case letter do
      v when v in ["a", "e", "i", "o", "u"] -> vowel_phoneme_modulation_points(v)
      c -> consonant_phoneme_modulation_points(c)
    end
  end

  def vowel_phoneme_pairs do
    %{
      "a" => ["æ", "ei"],
      "e" => ["e", "i:"],
      "i" => ["i", "ai"],
      "o" => ["o", "ou"],
      "u" => ["ʌ", "u:"]
    }
  end
end




