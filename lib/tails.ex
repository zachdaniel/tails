defmodule Tails do
  @colors_file Application.compile_env(:tails, :colors_file)
  @no_merge_classes Application.compile_env(:tails, :no_merge_classes) || []

  @colors (if @colors_file do
             @external_resource @colors_file

             @colors_file
             |> Path.expand()
             |> File.read!()
             |> Jason.decode!()
           else
             %{}
           end)

  @modifiers ~w(
    hover focus focus-within focus-visible active visited target first last only odd
    even first-of-type last-of-type only-of-type empty disabled enabled checked
    indeterminate default required valid invalid in-range out-of-range placeholder-shown
    autofill read-only open before after first-letter first-line marker selection file
    backdrop placeholder sm md lg xl 2xl dark portrait landscape motion-safe motion-reduce
    contrast-more contrast-less rtl ltr
    )

  @font_weights ~w(thin extralight light normal medium semibold bold extrabold black)
  @font_styles ~w(thin extralight light normal medium semibold bold extrabold black)
  @positions ~w(static fixed absolute relative sticky)
  @display ~w(
    block inline-block inline flex inline-flex table inline-table table-caption table-cell
    table-column table-column-group table-footer-group table-header-group table-row-group
    table-row flow-root grid inline-grid contents list-item hidden)

  @bg_sizes ~w(auto cover contain)
  @bg_repeats ~w(repeat no-repeat repeat-x repeat-y repeat-round repeat-space)
  @bg_positions ~w(bottom center left left-bottom left-top right right-bottom right-top top)
  @bg_blends ~w(normal multiply screen overlay darken lighten color-dodge color-burn hard-light soft-light difference exclusion hue saturation color luminosity)
  @bg_origins ~w(border padding content)
  @bg_attachments ~w(fixed local scroll)
  @bg_clips ~w(border padding content text)
  @bg_images ~w(none gradient-to-t gradient-to-tr gradient-to-r gradient-to-br gradient-to-b gradient-to-bl gradient-to-l gradient-to-tl)

  @text_overflow ~w(truncate text-ellipsis text-clip)

  @prefixed_with_values [
    font_weight: %{values: @font_weights, prefix: "font"},
    font_styles: %{values: @font_styles, prefix: "font"},
    bg_size: %{prefix: "bg", values: @bg_sizes},
    bg_repeat: %{prefix: "bg", values: @bg_repeats},
    bg_positions: %{prefix: "bg", values: @bg_positions},
    bg_blend: %{prefix: "bg-blend", values: @bg_blends},
    bg_origin: %{prefix: "bg-origin", values: @bg_origins},
    bg_clip: %{prefix: "bg-clip", values: @bg_clips},
    bg_image: %{prefix: "bg", values: @bg_images},
    bg_attachment: %{prefix: "bg", values: @bg_attachments}
  ]

  @with_values [
    position: %{values: @positions},
    display: %{values: @display},
    text_overflow: %{values: @text_overflow}
  ]

  @prefixed [
    bg: %{prefix: "bg"},
    text: %{prefix: "text"},
    grid_cols: %{prefix: "grid-cols"},
    grid_rows: %{prefix: "grid-rows"},
    width: %{prefix: "w"},
    height: %{prefix: "h"}
  ]

  @directional [p: %{prefix: "p"}, m: %{prefix: "m"}]

  @moduledoc """
  Tailwind class utilities like class merging.

  In most cases, only classes that we know all of the values for are merged.
  In some cases, we merge anything starting with a given prefix. Eventually,
  we will have tools to read your tailwind config to determine additional classes
  to merge, or have explicit configuration on additional merge logic.

  ## What classes are currently merged?

  ### Directional classes

  These classes support x/y/l/r suffix merging.

  - Padding - `p`
  - Margin - `m`

  ### Only explicitly known values

  Only explicitly known values will be merged, all others will be retained.

  #{Tails.Doc.doc_with_values(@with_values)}
  #{Tails.Doc.doc_prefix_with_values(@prefixed_with_values)}

  ### Any values matching prefix

  Any values matching the following prefixes will be merged with eachother respectively

  #{Tails.Doc.doc_prefixed(@prefixed)}
  """
  defstruct Keyword.keys(@directional) ++
              Keyword.keys(@prefixed) ++
              Keyword.keys(@with_values) ++
              Keyword.keys(@prefixed_with_values) ++
              [
                classes: MapSet.new(),
                variants: %{},
                variant: nil
              ]

  defmodule Directions do
    @moduledoc false
    defstruct [:l, :r, :t, :b, :x, :y, :all]

    @type t :: %__MODULE__{
            l: String.t(),
            r: String.t(),
            t: String.t(),
            b: String.t(),
            x: String.t(),
            y: String.t()
          }
  end

  @type t :: %__MODULE__{}

  @doc """
  Builds a class string out of a mixed list of inputs or a string.

  If the value is a string, we make a new `Tails` with it (essentially deduplicating it).

  If the value is a list, then for each item in the list:

  - If the value is a list, we call `classes/1` on it.
  - If it is a tuple, we discard it unless the second element is truthy.
  - Otherwise, we `to_string` it

  And then we merge the whole list up into one class string.

  This allows for conditional class rendering, arbitrarily nested. For example:

     iex> classes(["a", "b"])
     "a b"
     iex> classes([a: false, b: true])
     "b"
     iex> classes([[a: true, b: false], [c: false, d: true]])
     "a d"
  """
  def classes(nil), do: nil

  def classes(classes) when is_list(classes) do
    classes
    |> Enum.filter(fn
      {_classes, condition} ->
        condition

      _ ->
        true
    end)
    |> Enum.map(fn
      {classes, _} ->
        classes =
          if is_list(classes) do
            classes(classes)
          else
            classes
          end

        to_string(classes)

      classes ->
        classes =
          if is_list(classes) do
            classes(classes)
          else
            classes
          end

        to_string(classes)
    end)
    |> case do
      [classes] ->
        classes(classes)

      [classes | rest] ->
        rest
        |> Enum.reduce(classes, &merge(&2, &1))
        |> to_string()
    end
  end

  def classes(classes) when is_binary(classes) do
    classes
    |> new()
    |> to_string()
  end

  defp new(classes) do
    merge(%__MODULE__{}, classes)
  end

  @doc """
  Semantically merges two lists of tailwind classes, treating the first as a base and the second as overrides

  Generally, instead of calling `merge/2` you will call `classes/1` with a list of classes.

  See the module documentation for what classes will be merged/retained.

  Examples

      iex> merge("p-4", "p-2") |> to_string()
      "p-2"
      iex> merge("p-2", "p-4") |> to_string()
      "p-4"
      iex> merge("p-4", "px-2") |> to_string()
      "px-2 py-4"
      iex> merge("font-bold", "font-thin") |> to_string()
      "font-thin"
      iex> merge("block absolute", "fixed hidden") |> to_string()
      "fixed hidden"
      iex> merge("bg-blue-500", "bg-auto") |> to_string()
      "bg-auto bg-blue-500"
      iex> merge("bg-auto", "bg-repeat-x") |> to_string()
      "bg-auto bg-repeat-x"
      iex> merge("bg-blue-500", "bg-red-400") |> to_string()
      "bg-red-400"
      iex> merge("grid grid-cols-2 lg:grid-cols-3", "grid-cols-3 lg:grid-cols-4") |> to_string()
      "grid grid-cols-3 lg:grid-cols-4"
      iex> merge("font-normal text-black hover:text-primary-light-300", "text-primary-600 dark:text-primary-dark-400 font-bold") |> to_string()
      "font-bold text-primary-600 dark:text-primary-dark-400 hover:text-primary-light-300"

  Classes can be removed

      iex> merge("font-normal text-black", "remove:font-normal grid") |> to_string()
      "grid text-black"

  All preceeding classes can be removed

      iex> merge("font-normal text-black", "remove:* grid") |> to_string()
      "grid"

  Classes can be explicitly kept

      iex> merge("font-normal text-black", "remove:font-normal grid") |> to_string()
      "grid text-black"
  """
  def merge(tailwind, nil) when is_binary(tailwind), do: new(tailwind)
  def merge(%__MODULE__{} = tailwind, nil), do: new(tailwind)

  def merge(tailwind, classes) when is_list(tailwind) do
    merge(classes(tailwind), classes)
  end

  def merge(tailwind, classes) when is_list(classes) do
    merge(tailwind, classes(classes))
  end

  def merge(tailwind, classes) when is_binary(tailwind) do
    merge(new(tailwind), classes)
  end

  def merge(tailwind, classes) when is_binary(classes) do
    classes
    |> String.split()
    |> Enum.reduce(tailwind, &merge_class(&2, &1))
  end

  def merge(tailwind, %__MODULE__{} = classes) do
    merge(tailwind, to_string(classes))
  end

  def merge(_tailwind, value) do
    raise "Cannot merge #{inspect(value)}"
  end

  @doc "Merges a list of class strings. See `merge/2` for more"
  def merge(list) when is_list(list) do
    Enum.reduce(list, &merge(&2, &1))
  end

  @doc false
  def merge_class(tailwind, "keep:" <> class) do
    %{tailwind | classes: MapSet.put(tailwind.classes, class)}
  end

  def merge_class(_tailwind, "remove:*") do
    %__MODULE__{}
  end

  def merge_class(tailwind, "remove:" <> class) do
    remove(tailwind, class)
  end

  for class <- @no_merge_classes || [] do
    def merge_class(tailwind, unquote(class)) do
      %{tailwind | classes: MapSet.put(tailwind.classes, class)}
    end
  end

  for modifier <- @modifiers do
    def merge_class(tailwind, unquote(modifier) <> ":" <> rest) do
      rest = String.split(rest, ":")
      last = List.last(rest)
      modifiers = :lists.droplast(rest)

      key = Enum.sort([unquote(modifier) | modifiers])

      if Map.has_key?(tailwind.variants, key) do
        %{tailwind | variants: Map.update!(tailwind.variants, key, &merge_class(&1, last))}
      else
        %{
          tailwind
          | variants: Map.put(tailwind.variants, key, %{new(last) | variant: Enum.join(key, ":")})
        }
      end
    end
  end

  for {class, %{prefix: string_class}} <- @directional do
    def merge_class(tailwind, unquote(string_class) <> "-" <> value) do
      Map.put(tailwind, unquote(class), value)
    end

    def merge_class(%{unquote(class) => nil} = tailwind, unquote(string_class) <> "x-" <> value) do
      Map.put(tailwind, unquote(class), %Directions{x: value})
    end

    def merge_class(%{unquote(class) => all} = tailwind, unquote(string_class) <> "x-" <> value)
        when is_binary(all) do
      Map.put(tailwind, unquote(class), %Directions{y: all, x: value})
    end

    def merge_class(
          %{unquote(class) => %Directions{} = directions} = tailwind,
          unquote(string_class) <> "x-" <> value
        ) do
      Map.put(tailwind, unquote(class), %{directions | x: value, l: nil, r: nil})
    end

    def merge_class(%{unquote(class) => nil} = tailwind, unquote(string_class) <> "y-" <> value) do
      Map.put(tailwind, unquote(class), %Directions{y: value})
    end

    def merge_class(%{unquote(class) => all} = tailwind, unquote(string_class) <> "y-" <> value)
        when is_binary(all) do
      Map.put(tailwind, unquote(class), %Directions{x: all, y: value})
    end

    def merge_class(
          %{unquote(class) => %Directions{} = directions} = tailwind,
          unquote(string_class) <> "y-" <> value
        ) do
      Map.put(tailwind, unquote(class), %{directions | y: value, t: nil, b: nil})
    end
  end

  for {key, %{values: values, prefix: prefix}} <- @prefixed_with_values do
    def merge_class(tailwind, unquote(prefix) <> "-" <> new_value)
        when new_value in unquote(values) do
      Map.put(tailwind, unquote(key), new_value)
    end
  end

  for {key, %{values: values}} <- @with_values do
    def merge_class(tailwind, new_value) when new_value in unquote(values) do
      Map.put(tailwind, unquote(key), new_value)
    end
  end

  for {key, %{prefix: prefix}} <- @prefixed do
    def merge_class(tailwind, unquote(prefix) <> "-" <> new_value) do
      Map.put(tailwind, unquote(key), new_value)
    end
  end

  def merge_class(tailwind, class) do
    %{tailwind | classes: MapSet.put(tailwind.classes, class)}
  end

  @doc """
  Removes the given class from the class list.
  """
  for class <- @no_merge_classes || [] do
    def remove(tailwind, unquote(class)) do
      %{tailwind | classes: MapSet.delete(tailwind.classes, class)}
    end
  end

  for modifier <- @modifiers do
    def remove(tailwind, unquote(modifier) <> ":" <> rest) do
      rest = String.split(rest, ":")
      last = List.last(rest)
      modifiers = :lists.droplast(rest)

      key = Enum.sort([unquote(modifier) | modifiers])

      if Map.has_key?(tailwind.variants, key) do
        %{tailwind | variants: Map.update!(tailwind.variants, key, &remove(&1, last))}
      else
        %{
          tailwind
          | variants: Map.put(tailwind.variants, key, %{new(last) | variant: Enum.join(key, ":")})
        }
      end
    end
  end

  def remove(tails, class) do
    if MapSet.member?(tails.classes, class) do
      %{tails | classes: MapSet.delete(tails, class)}
    else
      # This is a bit of a hack, could maybe be optimized or fixed later

      # explicitly kept classes using `keep:` are in `classes`, so we keep them separate. The rest are classes we don't know about
      # so won't be affected by the `new/1` call below anyway.
      keep = tails.classes

      tails
      |> Map.put(:classes, MapSet.new())
      |> to_string()
      |> String.split(" ")
      |> Kernel.--([class])
      |> Enum.join(" ")
      |> new()
      |> Map.put(:classes, keep)
    end
  end

  @doc false
  def to_iodata(tailwind) do
    [
      Enum.map(@with_values, fn {key, _} ->
        simple(Map.get(tailwind, key), tailwind.variant)
      end),
      Enum.map(@directional, fn {key, %{prefix: prefix}} ->
        directional(Map.get(tailwind, key), prefix, tailwind.variant)
      end),
      Enum.map(@prefixed_with_values, fn {key, %{prefix: prefix}} ->
        prefix(prefix, Map.get(tailwind, key), tailwind.variant)
      end),
      Enum.map(@prefixed, fn {key, %{prefix: prefix}} ->
        prefix(prefix, Map.get(tailwind, key), tailwind.variant)
      end)
    ]
    |> add_variants(tailwind)
    |> add_classes(tailwind, tailwind.variant)
  end

  defp add_variants(iodata, tailwind) do
    [
      iodata,
      tailwind.variants
      |> Kernel.||(%{})
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.map(fn {_key, value} ->
        to_iodata(value)
      end)
    ]
  end

  defp add_classes(iodata, tailwind, variant) do
    Enum.concat(
      iodata,
      case tailwind.classes do
        nil ->
          []

        "" ->
          []

        classes ->
          if Enum.empty?(classes) do
            []
          else
            if variant do
              [" " | Enum.intersperse(Enum.map(tailwind.classes, &[variant, ":", &1]), " ")]
            else
              [" " | Enum.intersperse(tailwind.classes, " ")]
            end
          end
      end
    )
  end

  defp simple(nil, _), do: ""
  defp simple(value, nil), do: [" ", value]
  defp simple(value, variant), do: [" ", variant, ":", value]

  defp prefix(_prefix, nil, _), do: ""
  defp prefix(prefix, value, nil), do: [" ", prefix, "-", value]
  defp prefix(prefix, value, variant), do: [" ", variant, ":", prefix, "-", value]

  defp directional(nil, _key, _), do: ""

  defp directional(value, key, nil) when is_binary(value) do
    [" ", key, "-", value]
  end

  defp directional(value, key, variant) when is_binary(value) do
    [" ", variant, ":", key, "-", value]
  end

  defp directional(%Directions{l: l, r: r, t: t, b: b, x: x, y: y}, key, variant) do
    [
      direction(t, "t", key, variant),
      direction(b, "b", key, variant),
      direction(l, "l", key, variant),
      direction(r, "r", key, variant),
      direction(x, "x", key, variant),
      direction(y, "y", key, variant)
    ]
    |> Enum.filter(& &1)
  end

  defp direction(nil, _, _, _), do: ""

  defp direction(value, suffix, prefix, nil),
    do: [" ", prefix, suffix, "-", value]

  defp direction(value, suffix, prefix, variant),
    do: [" ", variant, ":", prefix, suffix, "-", value]

  defimpl String.Chars do
    def to_string(tailwind) do
      tailwind
      |> to_iodata()
      |> IO.iodata_to_binary()
      |> case do
        " " <> rest -> rest
        value -> value
      end
    end

    defp to_iodata(tailwind) do
      Tails.to_iodata(tailwind)
    end
  end

  defimpl Inspect do
    def inspect(tailwind, _opts) do
      "Tails.classes(\"#{to_string(tailwind)}\")"
    end
  end

  for {key, value} when is_binary(value) <- @colors do
    # sobelow_skip ["DOS.BinToAtom"]
    def unquote(:"#{String.replace(key, "-", "_")}")() do
      unquote(value)
    end
  end

  for {key, value} when is_map(value) <- @colors do
    for {suffix, value} when is_binary(value) <- value do
      if suffix == "DEFAULT" do
        # sobelow_skip ["DOS.BinToAtom"]
        def unquote(:"#{String.replace(key, "-", "_")}")() do
          unquote(value)
        end
      else
        # sobelow_skip ["DOS.BinToAtom"]
        def unquote(:"#{String.replace(key, "-", "_")}_#{String.replace(suffix, "-", "_")}")() do
          unquote(value)
        end
      end
    end
  end
end
