defmodule PolyrhythmGenerator.V1 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  def generate_parts(pulse) do
    File.mkdir("score")
    Enum.map(@letters, fn letter ->
      case letter == pulse do
        true -> pulse_part(pulse)
        false -> letter_part(letter, pulse)
      end
    end)
  end

  def pulse_part(letter) do
    str = ordered_coordinates(letter)
    |> Enum.map(fn {_, c} ->
      "\\time #{c}/8 \\repeat unfold #{c} { c8 }"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, str)
  end

  def letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse) |> Enum.into(%{})
    str = ordered_coordinates(letter)
    |> Enum.map(fn {i, c} ->
      pulse_count = pulse_coords[i]
      "\tuplet #{c}/#{pulse_count} { \\repeat unfold #{c} { c8 } }"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, str)
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

  def ordered_coordinates(letter) do
    {:ok, json} = File.read("processing/GraphParser/data/coordinates/#{letter}.json")
    letter_coordinates = Poison.Parser.parse!(json) |> Enum.map(&List.to_tuple/1) |> Enum.into(%{})
    Enum.sort_by(letter_coordinates, fn {i, _} -> i end)
  end
end
