defmodule ScoreGenerator do
  @alphabet ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @polyrhythm_generator PolyrhythmGenerator.V5
  @dynamics_generator DynamicsGenerator.V1

  def generate_parts(pulse) do
    File.mkdir("score")
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
    {:ok, pulse}
  end

  def letter_part(letter, pulse) do
    @polyrhythm_generator.letter_part(letter, pulse)
    |> @dynamics_generator.measures
    {:ok, letter}
  end
end

