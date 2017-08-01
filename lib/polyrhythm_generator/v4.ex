defmodule PolyrhythmGenerator.V4 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  import PolyrhythmGenerator

  def pulse_part(letter) do
    generate_part(letter, fn {_, c} ->
      "\\time #{c}/8 \\repeat unfold #{c} { c8 }"
    end)
  end

  def letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse) |> Enum.into(%{})
    music = part_ratios(letter, pulse)
    |> Enum.map(fn {i, r} ->
      pulse_count = pulse_coords[i]
      c = round(r * pulse_count)
      "\\tuplet #{c}/#{pulse_count} { \\repeat unfold #{c} { c8 } }"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, music)
    {:ok, letter}
  end

  def pulse_ratios(letter) do
    coordinates = ordered_coordinates(letter)
    {index, max_y} = Enum.max_by(coordinates, fn {x, y} -> y end)
    Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end)
  end

  def part_ratios(letter, pulse) do
    pulse = pulse_ratios(pulse)
    coordinates = ordered_coordinates(letter)
    {index, max_y} = Enum.max_by(coordinates, fn {x, y} -> y end)
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
