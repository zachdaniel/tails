defmodule Tails.Doc do
  @moduledoc false

  def doc_prefixed(prefixed) do
    prefixed
    |> Enum.map_join("\n", fn {key, %{prefix: prefix}} ->
      "- #{to_title(key)} - `#{prefix}`"
    end)
  end

  def doc_with_values(prefix_with_values) do
    prefix_with_values
    |> Enum.map_join("\n", fn {key, %{values: values}} ->
      "- #{to_title(key)} - " <> Enum.map_join(values, ", ", &"`#{&1}`")
    end)
  end

  def doc_prefix_with_values(prefix_with_values) do
    prefix_with_values
    |> Enum.map_join("\n", fn {key, %{prefix: prefix, values: values} = config} ->
      if config[:doc_values_placeholder] do
        "- #{to_title(key)} - " <> config[:doc_values_placeholder]
      else
        "- #{to_title(key)} - " <> Enum.map_join(values, ", ", &"`#{prefix}-#{&1}`")
      end
    end)
  end

  defp to_title(key) do
    key
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", fn
      "bg" ->
        "Background"

      other ->
        String.capitalize(other)
    end)
  end
end
