defmodule Mix.Tasks.Score.Compile do
  use Mix.Task

  @shortdoc "compiles score/score.ly to score/score.pdf"
  def run(_) do
    System.cmd("lilypond", ["-o", "score/score", "score/score.ly"])
  end
end
