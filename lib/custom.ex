defmodule Tails.Custom do
  defmacro __using__(opts) do
    quote generated: true, bind_quoted: [otp_app: opts[:otp_app], themes: opts[:themes]] do
      require Tails.Custom
      otp_app = otp_app || :tails

      if otp_app == :tails do
        @colors_file Application.compile_env(otp_app, :colors_file)
        @no_merge_classes Application.compile_env(otp_app, :no_merge_classes) || []
        @optimize_directions Application.compile_env(otp_app, :optimize_directions?)
        @themes themes || Application.compile_env(otp_app, :themes)
      else
        @colors_file Application.compile_env(otp_app, __MODULE__)[:colors_file]
        @no_merge_classes Application.compile_env(otp_app, __MODULE__)[:no_merge_classes] || []
        @optimize_directions Application.compile_env(otp_app, __MODULE__)[:optimize_directions?]
        @themes themes || Application.compile_env(otp_app, __MODULE__)[:themes]
      end

      @colors (if @colors_file do
                 @external_resource @colors_file

                 custom =
                   @colors_file
                   |> Path.expand()
                   |> File.read!()
                   |> Jason.decode!()

                 Map.merge(Tails.Colors.builtin_colors(), custom)
               else
                 Tails.Colors.builtin_colors()
               end)

      @all_colors Tails.Colors.all_color_classes(@colors)

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
      @outline_styles ~w(none dashed dotted double)

      @text_overflow ~w(truncate text-ellipsis text-clip)

      @prefixed_with_values [
        font_weight: %{prefix: "font", values: @font_weights},
        font_styles: %{prefix: "font", values: @font_styles},
        outline_style: %{prefix: "outline", values: @outline_styles, naked?: true},
        outline_color: %{prefix: "outline", values: @all_colors, doc_values_placeholder: "colors"},
        bg_size: %{prefix: "bg", values: @bg_sizes},
        bg_repeat: %{prefix: "bg", values: @bg_repeats},
        bg_positions: %{prefix: "bg", values: @bg_positions},
        bg_blend: %{prefix: "bg-blend", values: @bg_blends},
        bg_origin: %{prefix: "bg-origin", values: @bg_origins},
        bg_clip: %{prefix: "bg-clip", values: @bg_clips},
        bg_image: %{prefix: "bg", values: @bg_images},
        bg: %{prefix: "bg", values: @all_colors, doc_values_placeholder: "colors"},
        text_color: %{prefix: "text", values: @all_colors, doc_values_placeholder: "colors"},
        bg_attachment: %{prefix: "bg", values: @bg_attachments}
      ]

      @with_values [
        position: %{values: @positions},
        display: %{values: @display},
        text_overflow: %{values: @text_overflow}
      ]

      @prefixed [
        animate: %{prefix: "animate"},
        text: %{prefix: "text"},
        outline_width: %{prefix: "outline"},
        outline_offset: %{prefix: "outline-offset"},
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

      The preferred way to use tails classes the `classes/1` function. This gives you:

      1. conditional classes
      2. list merging (from left to right)
      3. arbitrary nesting

      For example:

      `classes(["mt-1 mx-2", ["pt-2": var1, "pb-4", var2], "mt-12": var3])`

      Will merge all classes from left to right, flattening the lists and conditionally
      including the classes where the associated value is true.

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
                    variant: nil,
                    theme: :default
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
        |> flatten_classes()
        |> Enum.reduce("", fn class, acc ->
          merge(acc, class)
        end)
        |> to_string()
      end

      def classes(classes) when is_binary(classes) do
        classes
        |> new()
        |> to_string()
      end

      defp new(classes) do
        merge(%__MODULE__{}, classes)
      end

      defp flatten_classes(classes) do
        classes
        |> Enum.filter(fn
          {_classes, condition} ->
            condition

          _ ->
            true
        end)
        |> Enum.map(fn
          {classes, _} ->
            classes

          classes ->
            classes
        end)
        |> Enum.flat_map(fn classes ->
          if is_list(classes) do
            flatten_classes(classes)
          else
            List.wrap(classes)
          end
        end)
        |> Enum.map(&to_string/1)
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
          iex> merge("mt-1", "-mt-1") |> to_string()
          "-mt-1"
          iex> merge("-mt-1", "-mb-1") |> to_string()
          "-my-1" # this only happens if `optimize_directions` is set to `true`
          iex> merge("grid grid-cols-2 lg:grid-cols-3", "grid-cols-3 lg:grid-cols-4") |> to_string()
          "grid grid-cols-3 lg:grid-cols-4"
          iex> merge("font-normal text-black hover:text-blue-300", "text-gray-600 dark:text-red-400 font-bold") |> to_string()
          "font-bold text-gray-600 hover:text-blue-300 dark:text-red-400"

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

      defp set_theme(tailwind, theme) do
        %{
          tailwind
          | theme: theme,
            variants:
              Map.new(tailwind.variants, fn {key, value} ->
                {key, set_theme(value, theme)}
              end)
        }
      end

      @doc false
      def merge_class(tailwind, "keep:" <> class) do
        %{tailwind | classes: MapSet.put(tailwind.classes, class)}
      end

      def merge_class(%{theme: theme}, "remove:*") do
        %__MODULE__{theme: theme}
      end

      def merge_class(tailwind, "remove:" <> class) do
        remove(tailwind, class)
      end

      for {theme, replacements} <- @themes || [] do
        def merge_class(tailwind, "theme:" <> unquote(to_string(theme))) do
          set_theme(tailwind, unquote(theme))
        end

        for {key, replacement} <- Tails.Custom.replacements(replacements) do
          def merge_class(%{theme: unquote(theme)} = tailwind, unquote(to_string(key))) do
            merge(tailwind, classes(unquote(replacement)))
          end
        end
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
              | variants:
                  Map.put(tailwind.variants, key, %{new(last) | variant: Enum.join(key, ":")})
            }
          end
        end
      end

      for {class, %{prefix: string_class}} <- @directional do
        def merge_class(tailwind, "-" <> unquote(string_class) <> "-" <> value) do
          Map.put(tailwind, unquote(class), "-#{value}")
        end

        def merge_class(tailwind, unquote(string_class) <> "-" <> value) do
          Map.put(tailwind, unquote(class), value)
        end

        def merge_class(
              %{unquote(class) => nil} = tailwind,
              "-" <> unquote(string_class) <> "x-" <> value
            ) do
          Map.put(tailwind, unquote(class), %Directions{x: "-#{value}"})
        end

        def merge_class(
              %{unquote(class) => nil} = tailwind,
              unquote(string_class) <> "x-" <> value
            ) do
          Map.put(tailwind, unquote(class), %Directions{x: value})
        end

        def merge_class(
              %{unquote(class) => all} = tailwind,
              "-" <> unquote(string_class) <> "x-" <> value
            )
            when is_binary(all) do
          Map.put(tailwind, unquote(class), %Directions{y: all, x: "-#{value}"})
        end

        def merge_class(
              %{unquote(class) => all} = tailwind,
              unquote(string_class) <> "x-" <> value
            )
            when is_binary(all) do
          Map.put(tailwind, unquote(class), %Directions{y: all, x: value})
        end

        def merge_class(
              %{unquote(class) => %Directions{} = directions} = tailwind,
              "-" <> unquote(string_class) <> "x-" <> value
            ) do
          Map.put(tailwind, unquote(class), %{directions | x: "-#{value}", l: nil, r: nil})
        end

        def merge_class(
              %{unquote(class) => %Directions{} = directions} = tailwind,
              unquote(string_class) <> "x-" <> value
            ) do
          Map.put(tailwind, unquote(class), %{directions | x: value, l: nil, r: nil})
        end

        def merge_class(
              %{unquote(class) => nil} = tailwind,
              "-" <> unquote(string_class) <> "y-" <> value
            ) do
          Map.put(tailwind, unquote(class), %Directions{y: "-#{value}"})
        end

        def merge_class(
              %{unquote(class) => nil} = tailwind,
              unquote(string_class) <> "y-" <> value
            ) do
          Map.put(tailwind, unquote(class), %Directions{y: value})
        end

        def merge_class(
              %{unquote(class) => all} = tailwind,
              "-" <> unquote(string_class) <> "y-" <> value
            )
            when is_binary(all) do
          Map.put(tailwind, unquote(class), %Directions{x: all, y: "-#{value}"})
        end

        def merge_class(
              %{unquote(class) => all} = tailwind,
              unquote(string_class) <> "y-" <> value
            )
            when is_binary(all) do
          Map.put(tailwind, unquote(class), %Directions{x: all, y: value})
        end

        def merge_class(
              %{unquote(class) => %Directions{} = directions} = tailwind,
              "-" <> unquote(string_class) <> "y-" <> value
            ) do
          Map.put(tailwind, unquote(class), %{directions | y: "-#{value}", t: nil, b: nil})
        end

        def merge_class(
              %{unquote(class) => %Directions{} = directions} = tailwind,
              unquote(string_class) <> "y-" <> value
            ) do
          Map.put(tailwind, unquote(class), %{directions | y: value, t: nil, b: nil})
        end

        for dir <- ~w(t b l r)a do
          {split, to} =
            if dir in [:t, :b] do
              to = if dir == :t, do: :b, else: :t
              {:y, to}
            else
              to = if dir == :l, do: :l, else: :r
              {:x, to}
            end

          def merge_class(
                %{unquote(class) => nil} = tailwind,
                "-" <> unquote(string_class) <> unquote(to_string(dir)) <> "-" <> value
              ) do
            Map.put(tailwind, unquote(class), %Directions{} |> Map.put(unquote(dir), "-#{value}"))
          end

          def merge_class(
                %{unquote(class) => nil} = tailwind,
                unquote(string_class) <> unquote(to_string(dir)) <> "-" <> value
              ) do
            Map.put(tailwind, unquote(class), %Directions{} |> Map.put(unquote(dir), value))
          end

          def merge_class(
                %{unquote(class) => %Directions{unquote(split) => split_value} = directions} =
                  tailwind,
                "-" <> unquote(string_class) <> unquote(to_string(dir)) <> "-" <> value
              )
              when not is_nil(split_value) do
            Map.put(
              tailwind,
              unquote(class),
              directions
              |> Map.put(unquote(dir), "-#{value}")
              |> Map.put(unquote(to), split_value)
              |> Map.put(unquote(split), nil)
            )
          end

          def merge_class(
                %{unquote(class) => %Directions{unquote(split) => split_value} = directions} =
                  tailwind,
                unquote(string_class) <> unquote(to_string(dir)) <> "-" <> value
              )
              when not is_nil(split_value) do
            Map.put(
              tailwind,
              unquote(class),
              directions
              |> Map.put(unquote(dir), value)
              |> Map.put(unquote(to), split_value)
              |> Map.put(unquote(split), nil)
            )
          end

          def merge_class(
                %{unquote(class) => %Directions{} = directions} = tailwind,
                "-" <> unquote(string_class) <> unquote(to_string(dir)) <> "-" <> value
              ) do
            Map.put(tailwind, unquote(class), Map.put(directions, unquote(dir), "-#{value}"))
          end

          def merge_class(
                %{unquote(class) => %Directions{} = directions} = tailwind,
                unquote(string_class) <> unquote(to_string(dir)) <> "-" <> value
              ) do
            Map.put(tailwind, unquote(class), Map.put(directions, unquote(dir), value))
          end
        end
      end

      for {key, %{values: values, prefix: prefix} = config} <- @prefixed_with_values do
        if config[:naked?] do
          def merge_class(tailwind, unquote(prefix)) do
            Map.put(tailwind, unquote(key), "")
          end
        end

        unless config[:no_arbitrary?] do
          def merge_class(tailwind, unquote(prefix) <> "-" <> "[" <> _ = new_value) do
            Map.put(tailwind, unquote(key), new_value)
          end
        end

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
              | variants:
                  Map.put(tailwind.variants, key, %{new(last) | variant: Enum.join(key, ":")})
            }
          end
        end
      end

      def remove(tails, class) do
        if MapSet.member?(tails.classes, class) do
          %{tails | classes: MapSet.delete(tails.classes, class)}
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
          Enum.map(@prefixed_with_values, fn {key, %{prefix: prefix} = config} ->
            prefix(prefix, Map.get(tailwind, key), tailwind.variant, config[:naked?])
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

      defp prefix(prefix, value, variant, naked? \\ false)
      defp prefix(_prefix, nil, _, _), do: ""
      defp prefix(prefix, value, nil, true), do: [" ", prefix]
      defp prefix(prefix, value, nil, _), do: [" ", prefix, "-", value]
      defp prefix(prefix, value, variant, true), do: [" ", variant, ":", prefix]
      defp prefix(prefix, value, variant, _), do: [" ", variant, ":", prefix, "-", value]

      defp directional(nil, _key, _), do: ""

      defp directional("-" <> value, key, nil) do
        [" -", key, "-", value]
      end

      defp directional(value, key, nil) when is_binary(value) do
        [" ", key, "-", value]
      end

      defp directional("-" <> value, key, variant) do
        [" ", variant, ":-", key, "-", value]
      end

      defp directional(value, key, variant) when is_binary(value) do
        [" ", variant, ":", key, "-", value]
      end

      if @optimize_directions do
        defp directional(%Directions{l: s, r: s, t: s, b: s}, key, variant) when not is_nil(s),
          do: directional(s, key, variant)

        defp directional(%Directions{x: s, y: s}, key, variant) when not is_nil(s),
          do: directional(s, key, variant)

        defp directional(%Directions{l: s, r: s, x: nil} = directions, key, variant)
             when not is_nil(s),
             do: directional(%{directions | x: s, l: nil, r: nil}, key, variant)

        defp directional(%Directions{t: s, b: s, y: nil} = directions, key, variant)
             when not is_nil(s),
             do: directional(%{directions | y: s, t: nil, b: nil}, key, variant)
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

      defp direction("-" <> value, suffix, prefix, nil),
        do: [" -", prefix, suffix, "-", value]

      defp direction(value, suffix, prefix, nil),
        do: [" ", prefix, suffix, "-", value]

      defp direction("-" <> value, suffix, prefix, variant),
        do: [" ", variant, ":-", prefix, suffix, "-", value]

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

        defp to_iodata(%mod{} = tailwind) do
          mod.to_iodata(tailwind)
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
  end

  @doc false
  def replacements(replacements, prefix \\ "") do
    Enum.flat_map(replacements, fn
      {key, value} when is_binary(value) ->
        [{add_to_prefix(prefix, key), value}]

      {key, value} when is_list(value) ->
        replacements(value, add_to_prefix(prefix, key))
    end)
  end

  defp add_to_prefix("", value), do: to_string(value)
  defp add_to_prefix(prefix, value), do: to_string(prefix) <> "-" <> to_string(value)
end
