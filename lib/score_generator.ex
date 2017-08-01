defmodule ScoreGenerator do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @pitches ~w( c g eqf btqf d fqs aqf bqf ctqs ef eqs ftqs atqf a cqs cs etqf e f fs af bf b bqs )
  @polyrhythm_generator PolyrhythmGenerator.V5
  @pitch_generator PitchGenerator.V2
  @dynamics_generator DynamicsGenerator.V1

  def generate_parts(pulse) do
    least_frequent = case pulse do
      "z" -> "q"
      _ -> "z"
    end
    Enum.map(@letters, fn letter ->
      case letter do
        ^pulse          -> pulse_part_to_lily(pulse)
        ^least_frequent -> least_frequent_part_to_lily(letter, pulse)
        _               -> letter_part_to_lily(letter, pulse)
      end
    end)
  end

  def pulse_part_to_lily(letter) do
    modulation_map = phoneme_modulation_points(letter) |> Enum.into(Map.new)
    part = letter |> @polyrhythm_generator.raw_pulse_part
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

  def apply_row([], _row_index, acc) do
    acc
  end
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
      "\\tuplet #{n}/#{d} { #{Enum.join(notes, " ")} }"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, part)
    {:ok, letter}
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

      "\\tuplet #{n}/#{d} { #{Enum.join(notes, " ")} }"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, part)
    {:ok, letter}
  end

  def measure_pitches(pulse) do
    @pitch_generator.generate_measure_pitches(pulse)
  end

  def write_lilypond_file(letter, music) do
    File.write("score/#{letter}.ly", """
    \\version "2.19.61"
    \\language "english"

    #{letter}Music = {
    \\clef "bass"
    #{music}
    }
    """)
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

