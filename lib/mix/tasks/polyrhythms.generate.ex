defmodule Mix.Tasks.Polyrhythms.Generate do
  use Mix.Task

  @shortdoc "generate polyrhythms using given generator"
  def run([version|_]) do
    module = Module.safe_concat(PolyrhythmGenerator, version)
    IO.inspect apply(module, :generate_parts, ["a"])
  end
end
