defmodule PolyrhythmGenerator.V5 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  import PolyrhythmGenerator

  def generate_parts(pulse) do
    Enum.map(@letters, fn letter ->
      case letter == pulse do
        true -> pulse_part_to_lily(pulse)
        false -> letter_part_to_lily(letter, pulse)
      end
    end)
  end

  def pulse_part(letter) do
    generate_part(letter, fn {_, c} ->
      "\\time #{c}/8 \\repeat unfold #{c} { c8 }"
    end)
  end

  def raw_pulse_part(letter) do
    ordered_coordinates(letter)
    |> Enum.map(fn {_, c} ->
      {{c, 8}, Stream.cycle(["c8"]) |> Enum.take(c)}
    end)
  end

  def raw_letter_part(letter, pulse) do
    pulse_coords = ordered_coordinates(pulse) |> Enum.into(%{})
    part_ratios(letter, pulse)
    |> Enum.map(fn {i, r} ->
      pulse_count = pulse_coords[i]
      c = round(r * pulse_count)
      c = case c == 0 do
        true -> 1
        false -> c
      end
      {{c, pulse_count}, Stream.cycle(["c8"]) |> Enum.take(c)}
    end)
  end

  def processed_letter_part(letter, pulse) do
    raw_part = raw_letter_part(letter, pulse)
    modulo_tuple = Map.get(converted_frequencies(), letter)
    process_part(raw_part, modulo_tuple)
  end

  def pulse_part_to_lily(letter) do
    part = letter |> raw_pulse_part
    |> Enum.map(fn {{n, d}, notes} ->
      "\\time #{n}/#{d} #{Enum.join(notes, " ")}"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, part)
    {:ok, letter}
  end

  def letter_part_to_lily(letter, pulse) do
    part = letter |> processed_letter_part(pulse)
    |> Enum.map(fn {{n, d}, notes} ->
      "\\tuplet #{n}/#{d} { #{Enum.join(notes, " ")} }"
    end) |> Enum.join("\n")
    write_lilypond_file(letter, part)
    {:ok, letter}
  end

  def process_part(raw, modulo), do: _process_part(raw, modulo, 0, [])

  def _process_part([], _, _, processed), do: Enum.reverse(processed)
  def _process_part([raw|rest], modulo = {1, m}, index, processed) do
    with {tuplet, notes} <- raw do
      processed_measure = Enum.with_index(notes, index) |> Enum.map(fn {_, i} ->
        case rem(i, m) == 0 do
          true -> "c8"
          false -> "r8"
        end
      end)
      new_index = index + length(notes)
      _process_part(rest, modulo, new_index, [{tuplet, processed_measure}|processed])
    end
  end
  def _process_part([raw|rest], modulo = {n, m}, index, processed) do
    with {tuplet, notes} <- raw do
      processed_measure = Enum.with_index(notes, index) |> Enum.map(fn {_, i} ->
        case rem(i, m) == n do
          true -> "r8"
          false -> "c8"
        end
      end)
      new_index = index + length(notes)
      _process_part(rest, modulo, new_index, [{tuplet, processed_measure}|processed])
    end
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
  end

  def pulse_ratios(letter) do
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_, y} -> y end)
    Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end)
  end

  def part_ratios(letter, pulse) do
    pulse = pulse_ratios(pulse)
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_, y} -> y end)
    pulse = Enum.into(pulse, %{})
    coords = Enum.into(Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end), %{})
    ratios = Enum.sort(Map.keys(coords))
    |> Enum.map(fn i ->
      {pn, pd} = pulse[i]
      {n, d} = coords[i]
      # multiply the fraction by the reciprocal of the pulse ratio so that the pulse always == 1
      {i, reduce(n * pd, d * pn)}
    end) |> Enum.map(fn {i, {x, y}} -> {i, x / y} end)
    letter_max = Enum.map(ratios, fn {_, r} -> r end) |> Enum.max
    letter_min = Enum.map(ratios, fn {_, r} -> r end) |> Enum.min
    # map the min/max to 1/16 <-> 2 and make sure every ratio is in that range
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

  def converted_frequencies do
    frequencies() |> Enum.map(fn {letter, freq} ->
      cond do
        freq >= 1 -> {letter, {round(Float.ceil(freq) - 1), round(Float.ceil(freq))}}
        freq >= 0.5 -> {letter, {1, 3}}
        true -> {letter, {1, round(1 / freq)}}
      end
    end) |> Enum.into(%{})
  end
end




