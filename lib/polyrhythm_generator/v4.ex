defmodule PolyrhythmGenerator.V4 do
  import PolyrhythmGenerator

  def pulse_part(letter) do
    ordered_coordinates(letter)
    |> Enum.map(fn {_, c} ->
      %Measure{
        time_signature: {c, 8}, tuplet: nil,
        events: (Stream.cycle(["c8"]) |> Enum.take(c))
      }
    end)
  end

  def letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse) |> Enum.into(%{})
    part_ratios(letter, pulse)
    |> Enum.map(fn {i, r} ->
      pulse_count = pulse_coords[i]
      c = round(r * pulse_count)
      %Measure{
        time_signature: nil, tuplet: {c, pulse_count},
        events: (Stream.cycle(["c8"]) |> Enum.take(c))
      }
    end)
  end

  def pulse_ratios(letter) do
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_x, y} -> y end)
    Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end)
  end

  def part_ratios(letter, pulse) do
    pulse = pulse_ratios(pulse)
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_x, y} -> y end)
    pulse = Enum.into(pulse, Map.new)
    coords = Enum.into(Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end), %{})
    ratios = Enum.sort(Map.keys(coords))
    |> Enum.map(fn i ->
      {pn, pd} = pulse[i]
      {n, d} = coords[i]
      {i, reduce(n * pd, d * pn)}
    end) |> Enum.map(fn {i, {x, y}} -> {i, x / y} end)
    {letter_min, letter_max} = Enum.map(ratios, fn {_, r} -> r end)
    |> Enum.min_max
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
end
