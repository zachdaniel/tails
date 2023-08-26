defmodule Tails.ColorClasses do
  @moduledoc false
  def color_classes(colors, prefix \\ "") do
    Enum.flat_map(colors, fn
      {"DEFAULT", _value} ->
        [prefix]

      {key, value} when is_binary(value) ->
        if prefix == "",
          do: [key],
          else: [prefix <> "-" <> key]

      {key, value} when is_map(value) ->
        new_prefix = if prefix == "", do: key, else: prefix <> "-" <> key
        color_classes(value, new_prefix)
    end)
  end
end
