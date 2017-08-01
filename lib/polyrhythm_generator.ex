defmodule PolyrhythmGenerator do
  def write_lilypond_file(letter, music) do
    File.write("score/#{letter}.ly", """
\\version "2.19.61"
\\language "english"

#{letter}Music = {
  \\clef "bass"
#{music}
  \\bar "|."
}
""")
  end

  def ordered_coordinates(letter) do
    {:ok, json} = File.read("processing/GraphParser/data/coordinates/#{letter}.json")
    letter_coordinates = Poison.Parser.parse!(json) |> Enum.map(&List.to_tuple/1) |> Enum.into(%{})
    Enum.sort_by(letter_coordinates, fn {i, _} -> i end)
  end

  def generate_part(letter, to_lily_func) do
    str = ordered_coordinates(letter)
    |> Enum.map(to_lily_func)
    |> Enum.join("\n")
    write_lilypond_file(letter, str)
    {:ok, letter}
  end

  def frequencies do
    %{
      "e" =>	12.702, "t" =>	9.056, "a" =>	8.167, "o" =>	7.507, "i" =>	6.966,
      "n" =>	6.749, "s" =>	6.327, "h" =>	6.094, "r" =>	5.987, "d" =>	4.253,
      "l" =>	4.025, "c" =>	2.782, "u" =>	2.758, "m" =>	2.406, "w" =>	2.360,
      "f" =>	2.228, "g" =>	2.015, "y" =>	1.974, "p" =>	1.929, "b" =>	1.492,
      "v" =>	0.978, "k" =>	0.772, "j" =>	0.153, "x" =>	0.150, "q" =>	0.095,
      "z" =>	0.074
    }
  end
end
