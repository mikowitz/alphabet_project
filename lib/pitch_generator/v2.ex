defmodule PitchGenerator.V2 do
  @pitches ~w( c g eqf btqf d fqs aqf bqf ctqs ef eqs ftqs atqf a cqs cs etqf e f fs af bf b bqs )
  @number_of_parts 24

  def calculate_conversion_steps do
    # all voices start on "c"
    starting = [{"c", @number_of_parts}]
    starting_index = 1
    build_steps(starting, starting_index, 0, [])
  end

  # if we've added every pitch, return the accumulated steps
  def build_steps(current, index, step_count, acc) when index == @number_of_parts do
    acc
  end
  # otherwise
  def build_steps(current, index, step_count, acc) do
    # find the pitch with the highest vox_count, and its index
    {{pitch, vox_count}, max_tuple_index} = Enum.with_index(current) |> Enum.max_by(fn {{_p, v}, _i} -> v end)
    # calculate the number of voices to switch to the next pitch, rounding up
    next_vox_count = round(vox_count / 2)
    new_max_tuple_vox_count = vox_count - next_vox_count
    # update the list with the new vox count for the pitch we found at the beginning
    next = List.replace_at(current, max_tuple_index, {pitch, new_max_tuple_vox_count})
    # and add the next pitch with its next_vox_count
    ++ [{Enum.at(@pitches, index), next_vox_count}]
    # add the correct number of conversion steps to the step accumulator
    new_acc = acc ++ generate_conversion_steps(pitch, Enum.at(@pitches, index), next_vox_count)
    # recur
    build_steps(next, index + 1, step_count + next_vox_count, new_acc)
  end

  def generate_conversion_steps(from, to, count) do
    Stream.cycle([{from, to}]) |> Enum.take(count)
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

  def letters_by_frequency(pulse) do
    least_frequent = case pulse do
      "z" -> "q"
      _ -> "z"
    end
    frequencies() |> Enum.to_list |> Enum.sort_by(fn {_, f} -> f end, &>=/2)
    |> Enum.map(fn {l, _} -> l end) |> List.delete(pulse) |> List.delete(least_frequent)
  end

  def starting_pitches(pulse) do
    letters_by_frequency(pulse) |> Enum.map(fn l ->
      {l, ["c", "c", "c"]}
    end)
  end

  def generate_measure_pitches(pulse) do
    starting_pitches(pulse)
    |> generate_splits(calculate_conversion_steps())
  end

  def generate_splits(pitches, []) do
    # if the step list is empty, make sure each part has 202 measures
    Enum.map(pitches, fn {letter, notes} ->
      new_notes = notes ++ (
        Stream.cycle([List.last(notes)])
        |> Enum.take(202 - length(notes))
      )
      {letter, new_notes}
    end)
  end
  def generate_splits(pitches, [{from, to}|rest_shifts]) do
    # find the first part still playing the pitch we need to shift
    {letter_to_shift, _} = Enum.find(pitches, fn {_, notes} -> List.last(notes) == from end)
    # iterate through
    next_pitches = Enum.map(pitches, fn {letter, notes} ->
      case letter == letter_to_shift do
        # if it's the part to switch, add 3 measures of the next pitch
        # 3 measures so space out the conversions more or less evenly (by measure count)
        true -> {letter, notes ++ [to, to, to]}
        # otherwise, just repeat the current pitch 3 times
        false -> {letter, notes ++ [List.last(notes), List.last(notes), List.last(notes)]}
      end
    end)
    generate_splits(next_pitches, rest_shifts)
  end
end


