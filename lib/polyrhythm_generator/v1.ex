defmodule PolyrhythmGenerator.V1 do
  import PolyrhythmGenerator

  def pulse_part(letter) do
    ordered_coordinates(letter)
    |> Enum.map(fn {_, c} ->
      %Measure{
        time_signature: {c, 8}, tuplet: nil,
        events: (Stream.cycle(["c8"]) |> Enum.take(c))
      }
    end)
    #generate_part(letter, fn {_, c} ->
      #measure = %Measure{
        #time_signature: {c, 8}, tuplet: nil,
        #events: (Stream.cycle(["c8"]) |> Enum.take(c))
      #}
    #end)
  end

  def letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse)
    #generate_part(letter, fn {i, c} ->
    ordered_coordinates(letter)
    |> Enum.map(fn {i, c} ->
      {_, pulse_count} = Enum.find(pulse_coords, fn {pi, _} -> pi == i end)
      %Measure{
        time_signature: nil, tuplet: {c, pulse_count},
        events: (Stream.cycle(["c8"]) |> Enum.take(c))
      }
    end)
  end
end
