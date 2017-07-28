defmodule GraphParser do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  def process_all! do
    Enum.map(@letters, fn letter ->
      spawn(__MODULE__, :process!, [letter])
    end)
    |> Enum.map(fn pid ->
      send pid, {self(), :check}
    end)
    start_receiving(0)
  end

  def start_receiving(n) do
    if n < length(@letters) do
      receive do
        {_pid, message} ->
          IO.puts message
          start_receiving(n + 1)
      end
    else
      {:ok, n}
    end
  end

  def process!(letter) do
    receive do
      {sender, :check} ->
        IO.puts("Processing #{letter}...")
        dimensions = get_dimensions(letter)
        run_processing(letter, dimensions)
        send sender, {self(), "done processing #{letter}"}
    end
  end

  defp get_dimensions(letter) do
    {str, 0} = System.cmd("identify", ["processing/GraphParser/data/originals/#{letter}.png"])
    [[_, w, h] | _] = Regex.scan(~r/(\d+)x(\d+)/, str)
    {w, h}
  end

  defp run_processing(letter, {w, h}) do
    System.cmd("processing-java", [
      "--sketch=#{System.cwd()}/processing/GraphParser",
      "--run", letter, w, h
    ])
  end
end

