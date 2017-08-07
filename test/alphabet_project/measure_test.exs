defmodule MeasureTest do
  use ExUnit.Case
  import Measure

  describe "to_lily/1" do
    test "returns a full measure rest for a measure w/time sig" do
      measure = %Measure{time_signature: {3, 8}, events: ["r8", "r8", "r8"]}
      assert to_lily(measure) == "  \\time 3/8 R8 * 3"
    end

    test "returns a full measure rest for a measure w/tuplet" do
      measure = %Measure{tuplet: {7, 8}, events: ["r8", "r8", "r8", "r8", "r8", "r8", "r8"]}
      assert to_lily(measure) == "  R8 * 8"
    end

    test "returns a time signature measure" do
      measure = %Measure{time_signature: {3, 8}, events: ["c8", "c8", "d8"]}
      assert to_lily(measure) == "  \\time 3/8 c8 [ c8 d8 ]"
    end

    test "returns a tuplet measure" do
      measure = %Measure{tuplet: {7, 8}, events: ["c8", "c8", "c8", "c8", "c8", "c8", "c8"]}
      assert to_lily(measure) == "  \\tuplet 7/8 { c8 [ c8 c8 c8 c8 c8 c8 ] }"
    end
  end

  describe "density/1" do
    test "it returns correctly" do
      measure = %Measure{tuplet: {10, 8},
        events: ["c8", "r8", "c8", "r8", "c8", "r8", "c8", "r8", "c8", "r8"]
      }
      assert density(measure) == 0.5
    end
  end
end
