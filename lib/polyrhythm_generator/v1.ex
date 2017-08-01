defmodule PolyrhythmGenerator.V1 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  import PolyrhythmGenerator

  def pulse_part(letter) do
    generate_part(letter, fn {_, c} ->
      measure = %Measure{
        time_signature: {c, 8}, tuplet: nil,
        events: (Stream.cycle(["c8"]) |> Enum.take(c))
      }
      "\\time #{c}/8 \\repeat unfold #{c} { c8 }"
    end)
  end

  def letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse)
    generate_part(letter, fn {i, c} ->
      {_, pulse_count} = Enum.find(pulse_coords, fn {pi, _} -> pi == i end)
      "\\tuplet #{c}/#{pulse_count} { \\repeat unfold #{c} { c8 } }"
    end)
  end
end
