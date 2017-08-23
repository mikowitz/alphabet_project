defmodule ScoreGenerator do
  @alphabet ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @polyrhythm_generator PolyrhythmGenerator.V5
  @dynamics_generator DynamicsGenerator.V1

  def generate_parts(pulse) do
    File.mkdir_p("score/parts")
    Enum.map(@alphabet, fn letter ->
      case letter do
        ^pulse -> pulse_part(pulse)
        _      -> letter_part(letter, pulse)
      end
    end)
  end

  def pulse_part(pulse) do
    @polyrhythm_generator.pulse_part(pulse)
    |> @dynamics_generator.measures
    |> Enum.map(&Measure.to_lily/1)
    |> Enum.join("\n")
    |> write_to_file(pulse)
    File.write!("score/parts/#{pulse}.ly", part_template(pulse, pulse))
    {:ok, pulse}
  end

  def letter_part(letter, pulse) do
    @polyrhythm_generator.letter_part(letter, pulse)
    |> @dynamics_generator.measures()
    |> @polyrhythm_generator.letter_part_to_lily(letter, pulse)
    |> Enum.map(&Measure.to_lily/1)
    |> Enum.join("\n")
    |> write_to_file(letter)
    File.write!("score/parts/#{letter}.ly", part_template(letter, pulse))
    {:ok, letter}
  end

  def write_to_file(lilypond, letter) do
    File.write("score/#{letter}.ly", """
\\version "2.19.61"
\\language "english"

#{letter}Music = {
  \\clef "bass"
#{lilypond}
  \\bar "|."
}
""")
  end

  defp part_template(pulse, pulse) do
    """
\\version "2.19.61"
\\language "english"

\\include "#{pulse}.ly"

#(set-default-paper-size "11x17")
#(set-global-staff-size 16)

\\paper {
  system-separator-markup = \slashSeparator
  system-system-spacing =
    #'((basic-distance . 25)
       (minimum-distance . 15)
       (padding . 3))
}

\\score {
  \\new Staff { \\#{pulse}Music }
}
"""
  end

  defp part_template(letter, pulse) do
    IO.puts "hello #{letter}"
    """
\\version "2.19.61"
\\language "english"

\\include "../#{pulse}.ly"
\\include "../#{letter}.ly"

#(set-default-paper-size "11x17")
#(set-global-staff-size 16)

\\paper {
  system-separator-markup = \\slashSeparator
  system-system-spacing =
    #'((basic-distance . 25)
       (minimum-distance . 15)
       (padding . 3))
}

\\score {
  \\new StaffGroup <<
    \\new Staff \\with {
      \\magnifyStaff #5/7
    } { \\#{pulse}Music }
    \\new Staff { \\#{letter}Music }
  >>
}
"""
  end
end

