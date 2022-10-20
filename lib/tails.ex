defmodule Tails do
  defstruct [
    :p,
    :m,
    :w,
    :font_weight,
    :font_style,
    :bg,
    :text,
    :grid_cols,
    :grid_rows,
    :display,
    :position,
    classes: MapSet.new(),
    variants: %{},
    variant: nil
  ]

  @colors_file Application.compile_env(:tails, :colors_file)

  @colors (if @colors_file do
             @external_resource @colors_file

             @colors_file
             |> Path.expand()
             |> File.read!()
             |> Jason.decode!()
           else
             %{}
           end)

  defmodule Directions do
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

  @type directional_value :: String.t() | Directions.t()

  @type t :: %__MODULE__{
          p: directional_value(),
          m: directional_value(),
          w: String.t()
        }

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
        to_string(classes)

      classes ->
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
      "hidden fixed"
      iex> merge("grid grid-cols-2 lg:grid-cols-3", "grid-cols-3 lg:grid-cols-4") |> to_string()
      "grid grid-cols-3 lg:grid-cols-4"
      iex> merge("font-normal text-black hover:text-primary-light-300", "text-primary-600 dark:text-primary-dark-400 font-bold") |> to_string()
      "font-bold text-primary-600 dark:text-primary-dark-400 hover:text-primary-light-300"
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

  def merge(list) when is_list(list) do
    Enum.reduce(list, &merge(&2, &1))
  end

  @font_weights ~w(thin extralight light normal medium semibold bold extrabold black)
  @font_styles ~w(thin extralight light normal medium semibold bold extrabold black)
  @positions ~w(static fixed absolute relative sticky)
  @display ~w(
    block inline-block inline flex inline-flex table inline-table table-caption table-cell
    table-column table-column-group table-footer-group table-header-group table-row-group
    table-row flow-root grid inline-grid contents list-item hidden)

  @prefixed_with_values [
    font_weight: %{values: @font_weights, prefix: "font-"},
    font_styles: %{values: @font_styles, prefix: "font-"}
  ]

  @with_values [
    position: %{values: @positions},
    display: %{values: @display}
  ]

  @prefixed [
    bg: %{prefix: "bg-"},
    text: %{prefix: "text-"},
    grid_cols: %{prefix: "grid-cols-"},
    grid_rows: %{prefix: "grid-rows-"}
]

  @directional ~w(p m)a

  @modifiers ~w(
    hover focus focus-within focus-visible active visited target first last only odd
    even first-of-type last-of-type only-of-type empty disabled enabled checked
    indeterminate default required valid invalid in-range out-of-range placeholder-shown
    autofill read-only open before after first-letter first-line marker selection file
    backdrop placeholder sm md lg xl 2xl dark portrait landscape motion-safe motion-reduce
    contrast-more contrast-less rtl ltr
    )

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

  for class <- @directional do
    string_class = to_string(class)

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
          unquote(string_class) <> "x" <> value
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
    def merge_class(tailwind, unquote(prefix) <> new_value) when new_value in unquote(values) do
      Map.put(tailwind, unquote(key), new_value)
    end
  end

  for {key, %{values: values}} <- @with_values do
    def merge_class(tailwind, new_value) when new_value in unquote(values) do
      Map.put(tailwind, unquote(key), new_value)
    end
  end

  for {key, %{prefix: prefix}} <- @prefixed do
    def merge_class(tailwind, unquote(prefix) <> new_value) do
      Map.put(tailwind, unquote(key), new_value)
    end
  end

  def merge_class(tailwind, class) do
    %{tailwind | classes: MapSet.put(tailwind.classes, class)}
  end

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
      [
        simple(tailwind.display, tailwind.variant),
        simple(tailwind.position, tailwind.variant),
        directional(tailwind.p, "p", tailwind.variant),
        directional(tailwind.m, "m", tailwind.variant),
        prefix("font", tailwind.font_weight, tailwind.variant),
        prefix("font", tailwind.font_style, tailwind.variant),
        prefix("bg", tailwind.bg, tailwind.variant),
        prefix("text", tailwind.text, tailwind.variant),
        prefix("grid-cols", tailwind.grid_cols, tailwind.variant),
        prefix("grid-rows", tailwind.grid_rows, tailwind.variant),
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
