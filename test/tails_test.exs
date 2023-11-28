defmodule TailsTest do
  use ExUnit.Case
  doctest Tails, import: true

  @doc """
  This is a copy of the original working version of the all_color_classes function, used to check
  that the current version produces the same result for single level of nesting colors that the
  original version did not support deeply-nested colors typical of custom themes.
  """
  def original_all_color_classes(colors) do
    Tails.Colors.builtin_colors()
    |> Map.merge(colors)
    |> Enum.flat_map(fn
      {key, value} when is_binary(value) ->
        [key]

      {key, value} when is_map(value) ->
        value
        |> Map.keys()
        |> Enum.map(fn
          "DEFAULT" ->
            key

          nested_key when is_binary(nested_key) ->
            key <> "-" <> nested_key
        end)
    end)
  end

  @single_nested_colors %{
    "black" => "#000",
    "theme" => %{"DEFAULT" => "#eee", "500" => "#888888"}
  }

  @deeply_nested_colors %{
    "theme" => %{
      "fine" => %{"color_a" => "#AAAAAA", "color_b" => "#BBBBBB"},
      "vibrant" => %{
        "DEFAULT" => "#111111",
        "color_c" => "#CCCCCC",
        "color_d" => %{"light" => "#AAAAAA", "dark" => "#222222"}
      }
    }
  }

  describe "Tails.Colors.all_color_classes" do
    test "returns theme color classes from single-nested colors" do
      classes = Tails.Colors.all_color_classes(@single_nested_colors)
      assert "theme-500" in classes
    end

    test "returns defaults for theme color classes from single-nested colors" do
      classes = Tails.Colors.all_color_classes(@single_nested_colors)
      assert "theme" in classes
    end

    test "returns deeply-nested theme colors" do
      classes = Tails.Colors.all_color_classes(@deeply_nested_colors)

      assert "theme-fine-color_a" in classes
      assert "theme-fine-color_b" in classes
      assert "theme-vibrant-color_c" in classes
      assert "theme-vibrant-color_d-light" in classes
      assert "theme-vibrant-color_d-dark" in classes
    end

    test "returns defaults for deeply-nested colors" do
      classes = Tails.Colors.all_color_classes(@deeply_nested_colors)

      assert "theme-vibrant" in classes
    end

    test "does not return classes without default from deeply-nested theme colors" do
      classes = Tails.Colors.all_color_classes(@deeply_nested_colors)

      refute "theme-fine" in classes
      refute "theme-vibrant-color_d" in classes
    end

    test "returns the same result as the original implementation for single-nested theme colors" do
      all_colors_orig = original_all_color_classes(@single_nested_colors)

      all_colors_current = Tails.Colors.all_color_classes(@single_nested_colors)

      assert all_colors_orig == all_colors_current
    end

    test "returns a different result from the original implementation for deeply-nested theme colors" do
      all_colors_orig = original_all_color_classes(@deeply_nested_colors)

      all_colors_current = Tails.Colors.all_color_classes(@deeply_nested_colors)

      refute all_colors_orig == all_colors_current
    end
  end

  describe "original implementation" do
    test "does not fully support deeply-nested theme colors" do
      classes = original_all_color_classes(@deeply_nested_colors)

      assert "theme-fine" in classes
      refute "theme-fine-color_a" in classes
      refute "theme-fine-color_b" in classes
      refute "theme-vibrant-color_c" in classes
      refute "theme-vibrant-color_d-light" in classes
      refute "theme-vibrant-color_d-dark" in classes
      refute "theme-vibrant-color_d" in classes
    end
  end

  describe "Tails.classes" do
    test "border-b-* and border-opacity-* do not override one another" do
      refute Tails.classes(["border-b-4 border-opacity-20"]) == "border-opacity-20"
      refute Tails.classes(["border-opacity-20 border-b-4"]) == "border-b-4"
    end
  end
end
