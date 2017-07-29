defmodule PolyrhythmGenerator.V3 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  import PolyrhythmGenerator

  def generate_parts(pulse) do
    Enum.map(@letters, fn letter ->
      case letter == pulse do
        true -> pulse_part(pulse)
        false -> letter_part(letter, pulse)
      end
    end)
  end

  def pulse_part(letter) do
    generate_part(letter, fn _ ->
      "\\time 4/4 c16[ c c c c c c c c c c c c c c c]"
    end)
  end

  def letter_part(letter, pulse) do
    music = part_ratios(letter, pulse)
    |> Enum.map(fn n ->
    "\\time 4/4 \\tuplet #{n}/16 \\repeat unfold #{n} { c16 }"
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
    pulse = Enum.into(pulse, %{})
    coords = Enum.into(Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end), %{})
    ratios = Enum.sort(Map.keys(coords))
    |> Enum.map(fn i ->
      {pn, pd} = pulse[i]
      {n, d} = coords[i]
      reduce(n * pd, d * pn)
    end) |> Enum.map(fn {x, y} -> x / y end)
    {letter_min, letter_max} = Enum.min_max(ratios)
    Enum.map(ratios, &__MODULE__.map(&1, letter_min, letter_max, 1/16, 2))
      |> Enum.map(fn x -> round(x * 16) end)
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


