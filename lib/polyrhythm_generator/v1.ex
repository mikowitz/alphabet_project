defmodule PolyrhythmGenerator.V1 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  import PolyrhythmGenerator

  def generate_parts(pulse) do
    File.mkdir("score")
    pulse_coords = ordered_coordinates(pulse)
    Enum.map(@letters, fn letter ->
      case letter == pulse do
        true -> pulse_part(pulse)
        false -> letter_part(letter, pulse_coords)
      end
    end)
  end

  def pulse_part(letter) do
    generate_part(letter, fn {_, c} ->
      "\\time #{c}/8 \\repeat unfold #{c} { c8 }"
    end)
  end

  def letter_part(letter, pulse_coords) do
    generate_part(letter, fn {i, c} ->
      {_, pulse_count} = Enum.find(pulse_coords, fn {pi, _} -> pi == i end)
      "\\tuplet #{c}/#{pulse_count} { \\repeat unfold #{c} { c8 } }"
    end)
  end
end
