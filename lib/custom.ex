defmodule Tails.Custom do
  @moduledoc """
  Use to create a custom tails module, that can be configured with `config :your_app, YourTails`

  Additionally, themes can be passed at runtime.

  Example Usage:

  ```elixir
  @themes %{
    default: %{...},
    dark: %{...}
  }
  use Tails.Custom, otp_app: :my_app, themes: @themes
  ```
  """

  defmacro __using__(opts) do
    quote location: :keep,
          generated: true,
          bind_quoted: [
            otp_app: opts[:otp_app],
            themes: opts[:themes],
            dark_themes: opts[:dark_themes]
          ] do
      require Tails.Custom
      otp_app = otp_app || :tails

      if otp_app == :tails do
        @colors_file Application.compile_env(otp_app, :colors_file)
        @color_classes Application.compile_env(otp_app, :color_classes) || []
        @no_merge_classes Application.compile_env(otp_app, :no_merge_classes) || []
        @dark_themes dark_themes || Application.compile_env(otp_app, :dark_themes)
        @themes themes || Application.compile_env(otp_app, :themes)
        @custom_variants Application.compile_env(otp_app, :variants) || []
        @fallback_to_colors Application.compile_env(otp_app, :fallback_to_colors) || false
      else
        @colors_file Application.compile_env(otp_app, __MODULE__)[:colors_file]
        @color_classes Application.compile_env(otp_app, __MODULE__)[:color_classes] || []
        @no_merge_classes Application.compile_env(otp_app, __MODULE__)[:no_merge_classes] || []
        @dark_themes dark_themes || Application.compile_env(otp_app, __MODULE__)[:dark_themes]
        @themes themes || Application.compile_env(otp_app, __MODULE__)[:themes]
        @custom_variants Application.compile_env(otp_app, __MODULE__)[:variants] || []
        @fallback_to_colors Application.compile_env(otp_app, __MODULE__)[:fallback_to_colors] ||
                              false
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

      @all_colors Tails.Colors.all_color_classes(@colors) ++ @color_classes

      @colors_by_size @all_colors |> Enum.group_by(&byte_size/1)

      @variants ~w(
        hover focus focus-within focus-visible active visited target first last only odd
        even first-of-type last-of-type only-of-type empty disabled enabled checked
        indeterminate default required valid invalid in-range out-of-range placeholder-shown
        autofill read-only open before after first-letter first-line marker selection file
        backdrop placeholder sm md lg xl 2xl dark portrait landscape motion-safe motion-reduce
        contrast-more contrast-less rtl ltr
      ) ++ @custom_variants

      @font_weights ~w(thin extralight light normal medium semibold bold extrabold black)
      @font_smoothings ~w(antialiased subpixel-antialiased)
      @font_styles ~w(italic non-italic)
      @positions ~w(static fixed absolute relative sticky)
      @display ~w(
        block inline-block inline flex inline-flex table inline-table table-caption table-cell
        table-column table-column-group table-footer-group table-header-group table-row-group
        table-row flow-root grid inline-grid contents list-item hidden
      )
      @bg_sizes ~w(auto cover contain)
      @bg_repeats ~w(repeat no-repeat repeat-x repeat-y repeat-round repeat-space)
      @bg_positions ~w(bottom center left left-bottom left-top right right-bottom right-top top)
      @bg_blends ~w(normal multiply screen overlay darken lighten color-dodge color-burn hard-light soft-light difference exclusion hue saturation color luminosity)
      @bg_origins ~w(border padding content)
      @bg_attachments ~w(fixed local scroll)
      @bg_clips ~w(border padding content text)
      @bg_images ~w(none gradient-to-t gradient-to-tr gradient-to-r gradient-to-br gradient-to-b gradient-to-bl gradient-to-l gradient-to-tl)
      @outline_styles ~w(none dashed dotted double)
      @aspect_ratios ~w(auto square video)
      @text_overflow ~w(truncate text-ellipsis text-clip)
      @break_values ~w(auto avoid all avoid-page page left right column)
      @break_inside_values ~w(auto avoid avoid-page avoid-column)
      @box_decoration_breaks ~w(clone slice)
      @box_sizes ~w(border content)
      @floats ~w(left right none)
      @clears ~w(left right both none)
      @isolations ~w(isolate isolation-auto)
      @flex_directions ~w(row row-reverse col col-reverse)
      @object_fits ~w(contain cover fill none scale-down)
      @object_positions ~w(bottom center left left-bottom left-top right right-bottom right-top top)
      @overflows ~w(auto hidden clip visible scroll)
      @overscrolls ~w(auto contain none)
      @visibilities ~w(visible invisible collapse)
      @flex_wraps ~w(wrap wrap-reverse nowrap)
      @flex_grow_shrinks ~w(1 auto initial none)
      @flex_specific_grow_shrinks ~w(0)
      @grid_flows ~w(row col dense row-dense col-dense)
      @auto_cols_rows ~w(auto min max fr)
      @justify_contents ~w(start end center between around evenly)
      @justify_items ~w(start end center stretch)
      @justify_selfs ~w(auto start end center stretch)
      @align_contents ~w(center start end between around evenly baseline)
      @align_items ~w(start end center baseline stretch)
      @align_selfs ~w(auto start end center stretch baseline)
      @place_contents ~w(center start end between around evenly baseline stretch)
      @place_items ~w(start end center baseline stretch)
      @place_selfs ~w(auto start end center stretch)
      @font_families ~w(sans serif mono)
      @font_variant_numerics ~w(normal-nums ordinal slashed-zero lining-nums oldstyle-nums proportional-nums tabular-nums diagonal-fractions stacked-fractions)
      @trackings ~w(tighter tight normal wide wider widest)
      @list_style_types ~w(none disc decimal)
      @list_style_positions ~w(inside outside)
      @text_alignments ~w(left center right justify start end)
      @text_decoration_styles ~w(solid double dotted dashed wavy)
      @text_decorations ~w(underline overline line-through no-underline)
      @text_transforms ~w(uppercase lowercase capitalize normal-case)
      @text_overflows ~w(truncate text-ellipses text-clip)
      @vertical_alignments ~w(baseline top middle bottom text-top text-bottom sub super)
      @whitespaces ~w(normal nowrap pre pre-line pre-wrap)
      @word_breaks ~w(normal words all keep)
      @border_styles ~w(solid dashed dotted double hidden none)
      @divide_styles ~w(solid dashed dotted double none)
      @outline_styles ~w(none dashed dotted double)
      @blend_modes ~w(
        normal multiply screen overlay darken lighten color-dodge color-burn
        hard-light soft-light difference exclusion hue saturation color luminosity
      )
      @table_layouts ~w(auto fixed)
      @mix_blend_modes @blend_modes ++ ~w(plus-lighter)
      @bg_blend_modes @blend_modes
      @border_collapse_modes ~w(collapse separate)
      @transition_timing_functions ~w(ease-linear ease-in ease-out ease-in-out)
      @transition_properties ~w(none all colors opacity shadow transform)
      @animations ~w(none spin ping pulse bounce)
      @transforms ~w(gpu none)
      @transform_origins ~w(center top top-right right bottom-right bottom bottom-left left top-left)
      @cursors ~w(
        auto default pointer wait text move help not-allowed none context-menu progress cell crosshair
        vertical-text alias copy no-drop grab grabbing all-scroll col-resize row-resize n-resize e-resize
        s-resize w-resize ne-resize nw-resize se-resize sw-resize ew-resize ns-resize nesw-resize nwse-resize
        zoom-in zoom-out
      )
      @pointer_events ~w(auto none)
      @resizes ~w(none y x)
      @scroll_behaviors ~w(auto smooth)
      @snap_aligns ~w(start end center align-none)
      @snap_stops ~w(normal always)
      @snap_types ~w(none x y both)
      @snap_strictness ~w(mandatory proximity)
      @touch_actions ~w(auto none pan-x pan-left pan-right pan-y pan-up pan-down pinch-zoom manipulation)
      @user_selects ~w(none text all auto)
      @will_change ~w(auto scroll contents transform)
      @digits Enum.map(0..9, &to_string/1)

      @prefixed_with_values [
        will_change: %{prefix: "will-change", values: @will_change},
        user_select: %{prefix: "select", values: @user_selects},
        touch_action: %{prefix: "touch", values: @touch_actions},
        snap_type: %{prefix: "snap", values: @snap_types},
        snap_strictness: %{prefix: "snap", values: @snap_strictness},
        snap_align: %{prefix: "snap", values: @snap_aligns},
        snap_stop: %{prefix: "snap", values: @snap_stops},
        scroll_behaviour: %{prefix: "scroll", values: @scroll_behaviors},
        resize: %{prefix: "resize", values: @resizes, naked?: true},
        pointer_events: %{prefix: "pointer-events", values: @pointer_events},
        cursor: %{prefix: "cursor", values: @cursors},
        transform: %{prefix: "transform", values: @transforms},
        animate: %{prefix: "animate", values: @animations},
        transition_property: %{prefix: "transition", values: @transition_properties, naked?: true},
        table_layout: %{prefix: "table", values: @table_layouts},
        border_collapse_mode: %{
          prefix: "border",
          values: @border_collapse_modes,
          no_arbitrary?: true
        },
        mix_blend_mode: %{prefix: "mix-blend", values: @mix_blend_modes},
        bg_blend_mode: %{prefix: "bg-blend", values: @bg_blend_modes},
        outline_styles: %{prefix: "outline", values: @outline_styles, naked?: true},
        divide_styles: %{prefix: "divide", values: @divide_styles},
        border_style: %{prefix: "border", values: @border_styles, no_arbitrary?: true},
        word_breaks: %{prefix: "break", values: @word_breaks},
        whitespace: %{prefix: "whitespace", values: @whitespaces},
        text_align: %{prefix: "text", values: @text_alignments, no_arbitrary?: true},
        vertical_align: %{prefix: "align", values: @vertical_alignments},
        text_decoration_style: %{prefix: "decoration", values: @text_decoration_styles},
        list_style_type: %{prefix: "list", values: @list_style_types},
        list_style_position: %{prefix: "list", values: @list_style_positions},
        tracking: %{prefix: "tracking", values: @trackings},
        place_content: %{prefix: "place-content", values: @place_contents},
        place_items: %{prefix: "place-items", values: @place_items},
        place_selfs: %{prefix: "place-selfs", values: @place_selfs},
        align_content: %{prefix: "content", values: @align_contents},
        align_items: %{prefix: "items", values: @align_items},
        align_selfs: %{prefix: "selfs", values: @align_selfs},
        auto_cols: %{prefix: "auto-cols", values: @auto_cols_rows},
        auto_rows: %{prefix: "auto-rows", values: @auto_cols_rows},
        grid_flow: %{prefix: "grid-flow", values: @grid_flows},
        justify_contents: %{prefix: "justify", values: @justify_contents},
        justify_items: %{prefix: "justify-items", values: @justify_items},
        justify_selfs: %{prefix: "justify-selfs", values: @justify_selfs},
        flex_grow_shrink: %{prefix: "flex", values: @flex_grow_shrinks},
        flex_direction: %{prefix: "flex", values: @flex_directions},
        shrink: %{prefix: "shrink", values: @flex_specific_grow_shrinks, naked?: true},
        grow: %{prefix: "grow", values: @flex_specific_grow_shrinks, naked?: true},
        flex_wrap: %{prefix: "flex", values: @flex_wraps},
        overflow: %{
          prefix: "overflow",
          values: @overflows
        },
        overflow_x: %{prefix: "overflow-x", values: @overflows},
        overflow_y: %{prefix: "overflow-y", values: @overflows},
        overscroll: %{
          prefix: "overscroll",
          values: @overscrolls
        },
        overscroll_x: %{prefix: "overscroll-x", values: @overscrolls},
        overscroll_y: %{prefix: "overscroll-y", values: @overscrolls},
        object_fit: %{prefix: "object", values: @object_fits},
        object_position: %{prefix: "object", values: @object_positions},
        float: %{prefix: "float", values: @floats},
        clear: %{prefix: "clear", values: @clears},
        break_after: %{prefix: "break-after", values: @break_values},
        break_before: %{prefix: "break-before", values: @break_values},
        break_inside: %{prefix: "break-inside", values: @break_inside_values},
        box_decoration: %{prefix: "box-decoration", values: @box_decoration_breaks},
        box_size: %{prefix: "box", values: @box_sizes},
        font_family: %{prefix: "font", values: @font_families},
        font_weight: %{prefix: "font", values: @font_weights},
        aspect_ratio: %{prefix: "aspect", values: @aspect_ratios},
        outline_style: %{prefix: "outline", values: @outline_styles, naked?: true},
        bg_size: %{prefix: "bg", values: @bg_sizes},
        bg_repeat: %{prefix: "bg", values: @bg_repeats},
        bg_positions: %{prefix: "bg", values: @bg_positions},
        bg_blend: %{prefix: "bg-blend", values: @bg_blends},
        bg_origin: %{prefix: "bg-origin", values: @bg_origins},
        bg_clip: %{prefix: "bg-clip", values: @bg_clips},
        bg_image: %{prefix: "bg", values: @bg_images},
        bg_attachment: %{prefix: "bg", values: @bg_attachments},
        col: %{prefix: "col", values: ~w(auto)}
      ]

      @prefixed_with_colors [
        fill_color: %{prefix: "fill"},
        outline_color: %{prefix: "outline"},
        caret_color: %{prefix: "caret"},
        accent_color: %{prefix: "accent"},
        ring_color: %{prefix: "ring"},
        shadow_color: %{prefix: "shadow"},
        ring_offset_color: %{prefix: "ring-offset"},
        divide_color: %{prefix: "divide"},
        border_color: %{prefix: "border"},
        border_color_y: %{prefix: "border-y", clears: [:border_color_t, :border_color_b]},
        border_color_x: %{prefix: "border-x", clears: [:border_color_l, :border_color_r]},
        border_color_t: %{prefix: "border-t"},
        border_color_r: %{prefix: "border-r"},
        border_color_b: %{prefix: "border-b"},
        border_color_l: %{prefix: "border-l"},
        text_decoration_color: %{prefix: "decoration"},
        bg: %{prefix: "bg"},
        text_color: %{prefix: "text"}
      ]

      @with_values [
        sr_only: %{values: ~w(sr-only not-sr-only)},
        transition_timing_function: %{
          values: @transition_timing_functions,
          arbitrary_prefix: "ease-"
        },
        text_overflows: %{values: @text_overflows},
        text_transform: %{values: @text_transforms},
        text_decoration: %{values: @text_decorations},
        isolation: %{values: @isolations},
        position: %{values: @positions},
        font_smoothing: %{values: @font_smoothings},
        font_style: %{values: @font_styles},
        display: %{values: @display},
        visibility: %{values: @visibilities},
        text_overflow: %{values: @text_overflow}
      ]

      @singletons ~w(container content-none space-y-reverse space-x-reverse divide-y-reverse divide-x-reverse ring-inset filter-none backdrop-filter-none col-auto row-auto)
                  |> Enum.concat(@font_variant_numerics)
                  |> Enum.map(&String.to_atom/1)

      @prefixed [
        stroke_width: %{prefix: "stroke"},
        rotate: %{prefix: "rotate"},
        translate: %{prefix: "translate"},
        translate_x: %{prefix: "translate-x"},
        translate_y: %{prefix: "translate-y"},
        scale_x: %{prefix: "scale-x"},
        scale_y: %{prefix: "scale-y"},
        scale: %{prefix: "scale"},
        skew_x: %{prefix: "skew-x"},
        skew_y: %{prefix: "skew-y"},
        duration: %{prefix: "duration"},
        delay: %{prefix: "delay"},
        blur: %{prefix: "blur", naked?: true},
        brightness: %{prefix: "brightness"},
        contrast: %{prefix: "contrast"},
        sepia: %{prefix: "sepia"},
        hue_rotate: %{prefix: "hue-rotate"},
        grayscale: %{prefix: "grayscale", naked?: true},
        saturate: %{prefix: "saturate"},
        invert: %{prefix: "invert", naked?: true},
        drop_shadow: %{prefix: "drop-shadow", naked?: true},
        shadow: %{prefix: "shadow", naked?: true},
        backdrop_blur: %{prefix: "backdrop-blur", naked?: true},
        backdrop_brightness: %{prefix: "backdrop-brightness"},
        backdrop_contrast: %{prefix: "backdrop-contrast"},
        backdrop_sepia: %{prefix: "backdrop-sepia"},
        backdrop_hue_rotate: %{prefix: "backdrop-hue-rotate"},
        backdrop_grayscale: %{prefix: "backdrop-grayscale", naked?: true},
        backdrop_saturate: %{prefix: "backdrop-saturate"},
        backdrop_invert: %{prefix: "backdrop-invert", naked?: true},
        backdrop_opacity: %{prefix: "backdrop-opacity"},
        border_opacity: %{prefix: "border-opacity"},
        ring_width: %{prefix: "ring", naked?: true, wont_overwrite: ~w(ring-inset), digits?: true},
        underline_offset: %{prefix: "underline-offset"},
        text_decoration_thickness: %{prefix: "decoration"},
        text_indent: %{prefix: "indent"},
        leading: %{prefix: "leading"},
        gap: %{prefix: "gap"},
        gap_x: %{prefix: "gap-x"},
        gap_y: %{prefix: "gap-y"},
        order: %{prefix: "order"},
        basis: %{prefix: "basis"},
        space_x: %{prefix: "space-x"},
        space_y: %{prefix: "space-y"},
        z: %{prefix: "z"},
        left: %{prefix: "left"},
        right: %{prefix: "right"},
        top: %{prefix: "top"},
        bottom: %{prefix: "bottom"},
        inset: %{prefix: "inset"},
        inset_y: %{prefix: "inset-y"},
        inset_x: %{prefix: "inset-x"},
        columns: %{prefix: "columns"},
        col_span: %{prefix: "col-span"},
        col_start: %{prefix: "col-start"},
        col_end: %{prefix: "col-end"},
        row_span: %{prefix: "row-span"},
        row_start: %{prefix: "row-start"},
        row_end: %{prefix: "row-end"},
        font_size: %{prefix: "text"},
        outline_width: %{prefix: "outline"},
        outline_offset: %{prefix: "outline-offset"},
        grid_cols: %{prefix: "grid-cols"},
        grid_rows: %{prefix: "grid-rows"},
        width: %{prefix: "w"},
        min_width: %{prefix: "min-w"},
        max_width: %{prefix: "max-w"},
        height: %{prefix: "h"},
        min_height: %{prefix: "min-h"},
        max_height: %{prefix: "max-h"}
      ]

      @simple_overwrite_rules %{
        "col-auto" => ~w(col_span col_start col_end)a,
        "row-auto" => ~w(row_span col_start col_end)a
      }

      @directional [
        p: %{prefix: "p", negative?: true, digits?: true},
        m: %{prefix: "m", negative?: true, digits?: true},
        rounded: %{prefix: "rounded", naked?: true},
        scroll_m: %{prefix: "scroll-m", negative?: true, digits?: true},
        scroll_p: %{prefix: "scroll-p", negative?: true, digits?: true},
        divide: %{prefix: "divide", dash_suffix?: true, values: ["reverse"], digits?: true},
        border_width: %{
          prefix: "border",
          dash_suffix?: true,
          negative?: true,
          digits?: true
        },
        border_spacing: %{
          prefix: "border-spacing",
          dash_suffix?: true,
          negative?: true,
          digits?: true
        }
      ]

      @browser_color_values ~w(
        silver gray white maroon red purple fuchsia green lime olive yellow navy blue teal aqua aliceblue
        antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood
        cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod
        darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon
        darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray
        dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray
        green greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen
        lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink
        lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen
        linen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue
        mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy
        oldlace olive olivedrab orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip
        peachpuff peru pink plum powderblue purple red rosybrown royalblue saddlebrown salmon sandybrown seagreen
        seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle
        tomato turquoise violet wheat white whitesmoke yellow yellowgreen
      )

      @browser_color_prefixes ~w[# rgb( rgba( hsl( hsla(]

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
      #{Tails.Doc.doc_prefixed_with_colors(@prefixed_with_colors)}

      ### Any values matching prefix

      Any values matching the following prefixes will be merged with each other respectively

      #{Tails.Doc.doc_prefixed(@prefixed)}

      ### Singletons

      The following classes are tracked as special classes, but don't have any special merge behavior
      because they either compose with other similar classes or have no conflicts

      #{Enum.map_join(@singletons, "\n", &"* #{&1}")}
      """
      defstruct Keyword.keys(@directional) ++
                  Keyword.keys(@prefixed) ++
                  Keyword.keys(@with_values) ++
                  Keyword.keys(@prefixed_with_colors) ++
                  Keyword.keys(@prefixed_with_values) ++
                  @singletons ++
                  [
                    classes: MapSet.new(),
                    variants: %{},
                    variant: nil,
                    fallback: :default,
                    theme: :default
                  ]

      defmodule Directions do
        @moduledoc false
        defstruct [:l, :r, :t, :b, :tl, :tr, :br, :bl, :x, :y, :all]

        @type t :: %__MODULE__{
                l: String.t(),
                r: String.t(),
                t: String.t(),
                b: String.t(),
                tl: String.t(),
                tr: String.t(),
                br: String.t(),
                bl: String.t(),
                x: String.t(),
                y: String.t()
              }
      end

      @type t :: %__MODULE__{}

      @doc """
      Builds a class string out of a mixed list of inputs or a string. You can use the `~t` sigil as a shortcut.

      If the value is a string, we make a new `Tails` with it (essentially deduplicating it).

      If the value is a list, then for each item in the list:

      - If the value is a list, we call `classes/1` on it.
      - If it is a tuple, we discard it unless the second element is truthy.
      - Otherwise, we `to_string` it

      And then we merge the whole list up into one class string.

      This allows for conditional class rendering, arbitrarily nested.

      ## Examples

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

      @doc "Trims nil values and returns a map"
      def debug(value) do
        value =
          case value do
            %__MODULE__{} ->
              value

            value ->
              new(value)
          end

        value
        |> Map.from_struct()
        |> Enum.reject(&is_nil(elem(&1, 1)))
        |> Map.new()
      end

      @doc """
      Builds a class string out of a mixed list of inputs or a string.

      See `classes/1` for more information.

          iex> ~t([[a: true, b: false], [c: false, d: true]])
          "a d"
      """
      defmacro sigil_t(contents, _flags) do
        quote do
          classes([Code.eval_string(unquote(contents), []) |> elem(0)])
        end
      end

      def new(classes) do
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
          "p-4 px-2"
          iex> merge("font-bold", "font-thin") |> to_string()
          "font-thin"
          iex> merge("block absolute", "fixed hidden") |> to_string()
          "fixed hidden"
          iex> merge("bg-blue-500", "bg-auto") |> to_string()
          "bg-blue-500 bg-auto"
          iex> merge("bg-auto", "bg-repeat-x") |> to_string()
          "bg-auto bg-repeat-x"
          iex> merge("bg-blue-500", "bg-red-400") |> to_string()
          "bg-red-400"
          iex> merge("grid grid-cols-2 lg:grid-cols-3", "grid-cols-3 lg:grid-cols-4") |> to_string()
          "grid grid-cols-3 lg:grid-cols-4"
          iex> merge("min-h-2", "min-h-[1rem]") |> to_string()
          "min-h-[1rem]"
          iex> merge("min-w-2", "min-h-[1rem]") |> to_string()
          "min-w-2 min-h-[1rem]"
          iex> merge("border-2", "border-gray-500") |> to_string()
          "border-2 border-gray-500"
          iex> merge("rounded-lg", "rounded") |> to_string()
          "rounded"
          iex> merge("rounded", "rounded-lg") |> to_string()
          "rounded-lg"
          iex> merge("rounded", "px-2") |> to_string()
          "px-2 rounded"
          iex> merge("border-separate", "border-spacing-1") |> to_string()
          "border-spacing-1 border-separate"
          iex> merge("shadow", "shadow-md") |> to_string()
          "shadow-md"
          iex> merge("shadow-none", "shadow-inner") |> to_string()
          "shadow-inner"
          iex> merge("shadow-lg", "shadow") |> to_string()
          "shadow"
          iex> merge("text-xl", "text-[16px]") |> to_string()
          "text-[16px]"
          iex> merge("text-white", "text-[#000]") |> to_string()
          "text-[#000]"
          iex> merge("text-center text-xl text-white", "text-[16px] text-[#000]") |> to_string()
          "text-[#000] text-center text-[16px]"
          iex> merge("border-b-4 border-opacity-20") |> to_string()
          "border-b-4 border-opacity-20"
          iex> merge("border-black border-b-4 border-opacity-20") |> to_string()
          "border-b-4 border-black border-opacity-20"
          iex> merge("border-2 border-px") |> to_string()
          "border-px"

      Classes can be removed

          iex> merge("font-normal text-black", "remove:font-normal grid") |> to_string()
          "grid text-black"

      All preceding classes can be removed

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
        Enum.reduce(list, %__MODULE__{}, &merge(&2, &1))
      end

      def merge(value) when not is_list(value) do
        merge([value])
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

      defp alter_dark_theme(%{variant: "dark"} = tailwind, fallback, theme) do
        tailwind
        |> set_theme(theme)
        |> set_fallback_theme(fallback)
      end

      defp alter_dark_theme(tailwind, fallback, theme) do
        %{
          tailwind
          | variants:
              Map.new(tailwind.variants, fn {key, value} ->
                {key, alter_dark_theme(value, fallback, theme)}
              end)
        }
      end

      defp set_fallback_theme(tailwind, fallback) do
        %{
          tailwind
          | fallback: fallback,
            variants:
              Map.new(tailwind.variants, fn {key, value} ->
                {key, set_fallback_theme(value, fallback)}
              end)
        }
      end

      for {source_class, overwrites} <- @simple_overwrite_rules do
        for overwrite <- overwrites do
          def merge_class(%{unquote(overwrite) => v} = tailwind, unquote(to_string(source_class)))
              when not is_nil(v) do
            tailwind
            |> Map.put(unquote(overwrite), nil)
            |> merge_class(unquote(to_string(source_class)))
          end
        end
      end

      @doc false
      def merge_class(tailwind, "keep:" <> class) do
        %{tailwind | classes: MapSet.put(tailwind.classes, class)}
      end

      def merge_class(%{theme: theme, variants: variants}, "remove:*") do
        %__MODULE__{
          theme: theme,
          variants:
            Map.new(variants, fn {key, value} ->
              {key, merge_class(value, "remove:*")}
            end)
        }
      end

      def merge_class(tailwind, "remove:" <> class) do
        remove(tailwind, class)
      end

      replacements =
        Enum.flat_map(@themes || [], fn {theme, replacements} ->
          replacements
          |> Tails.Custom.replacements()
          |> Enum.map(fn {key, replacement} ->
            {theme, key, replacement}
          end)
        end)

      for {theme, _replacements} <- @themes || [] do
        if @dark_themes[theme] do
          def merge_class(tailwind, "theme:" <> unquote(to_string(theme))) do
            tailwind
            |> set_theme(unquote(theme))
            |> alter_dark_theme(unquote(theme), unquote(@dark_themes[theme]))
          end
        else
          def merge_class(tailwind, "theme:" <> unquote(to_string(theme))) do
            set_theme(tailwind, unquote(theme))
          end
        end
      end

      # First match on exact theme matches
      for {theme, key, replacement} <- replacements do
        dark_replacement =
          Enum.find_value(replacements, fn {r_theme, r_key, dark_replacement} ->
            if r_theme == @dark_themes[theme] && r_key == key do
              dark_replacement
            end
          end)

        if dark_replacement do
          def merge_class(%{theme: theme} = tailwind, unquote(to_string(key)))
              when theme in [unquote(theme), unquote(to_string(theme))] do
            merge(tailwind, classes([unquote(replacement), unquote("dark:#{dark_replacement}")]))
          end
        else
          def merge_class(%{theme: theme} = tailwind, unquote(to_string(key)))
              when theme in [unquote(theme), unquote(to_string(theme))] do
            merge(tailwind, classes(unquote(replacement)))
          end
        end
      end

      # # Then match on each theme as a potential fallback theme
      # # We don't check for a matching dark theme when falling back
      for {theme, key, replacement} <- replacements do
        def merge_class(%{fallback: theme} = tailwind, unquote(to_string(key)))
            when theme in [unquote(theme), unquote(to_string(theme))] do
          merge(tailwind, classes(unquote(replacement)))
        end
      end

      # final fallback to default
      for {:default, key, replacement} <- replacements do
        dark_replacement =
          Enum.find_value(replacements, fn {r_theme, r_key, dark_replacement} ->
            if r_theme == @dark_themes[:default] && r_key == key do
              dark_replacement
            end
          end)

        if dark_replacement do
          def merge_class(tailwind, unquote(to_string(key))) do
            merge(
              tailwind,
              classes([unquote(replacement), unquote("dark:#{dark_replacement}")])
            )
          end
        else
          def merge_class(tailwind, unquote(to_string(key))) do
            merge(tailwind, classes(unquote(replacement)))
          end
        end
      end

      for class <- @no_merge_classes || [] do
        def merge_class(tailwind, unquote(class)) do
          %{tailwind | classes: MapSet.put(tailwind.classes, class)}
        end
      end

      for modifier <- @variants do
        def merge_class(tailwind, unquote(modifier) <> ":" <> rest) do
          rest = String.split(rest, ":")
          last = List.last(rest)
          variants = :lists.droplast(rest)

          key = [unquote(modifier) | variants]

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

      for value <- @singletons do
        def merge_class(tailwind, unquote(to_string(value))) do
          Map.put(tailwind, unquote(value), true)
        end
      end

      for {key, %{values: values, prefix: prefix} = config} <-
            Enum.sort_by(@prefixed_with_values, fn {_, %{prefix: prefix}} ->
              -String.length(prefix)
            end) do
        if config[:naked?] do
          def merge_class(tailwind, unquote(prefix)) do
            Map.put(tailwind, unquote(key), "")
          end
        end

        unless config[:no_arbitrary?] do
          if config[:arbitrary_prefix] do
            def merge_class(
                  tailwind,
                  unquote(config[:arbitrary_prefix]) <> "-[" <> new_value
                ) do
              Map.put(tailwind, unquote(key), "[" <> new_value)
            end
          else
            def merge_class(tailwind, unquote(prefix) <> "-[" <> new_value) do
              Map.put(tailwind, unquote(key), "[" <> new_value)
            end
          end
        end

        def merge_class(tailwind, unquote(prefix) <> "-" <> new_value)
            when new_value in unquote(values) do
          Map.put(tailwind, unquote(key), new_value)
        end
      end

      @one_through_one_hundred 1..100 |> Enum.map(&to_string/1) |> Enum.take(11)

      for {key, %{prefix: prefix} = config} <-
            Enum.sort_by(@prefixed_with_colors, fn {_, %{prefix: prefix}} ->
              -String.length(prefix)
            end) do
        @clears Keyword.new(config[:clears] || [], &{&1, nil})
        def merge_class(
              tailwind,
              unquote(prefix) <> "-" <> "[currentcolor]"
            ) do
          struct(tailwind, [{unquote(key), "[currentcolor]"} | @clears])
        end

        for color_prefix <- @browser_color_prefixes do
          def merge_class(
                tailwind,
                unquote(prefix) <> "-" <> "[" <> unquote(color_prefix) <> new_value
              ) do
            struct(tailwind, [
              {unquote(key), "[#{unquote(color_prefix)}" <> new_value} | @clears
            ])
          end
        end

        for color_value <- @browser_color_values do
          match = "[#{color_value}]"

          def merge_class(tailwind, unquote(prefix) <> "-" <> unquote(match)) do
            struct(tailwind, [{unquote(key), unquote(match)} | @clears])
          end
        end

        def merge_class(tailwind, unquote(prefix) <> "-" <> new_value)
            when new_value in @all_colors do
          struct(tailwind, [{unquote(key), new_value} | @clears])
        end

        for {size, colors} <- @colors_by_size do
          def merge_class(
                tailwind,
                unquote(prefix) <>
                  "-" <> <<new_value::binary-size(unquote(size))>> <> "/" <> suffix
              )
              when new_value in unquote(colors) do
            struct(tailwind, [{unquote(key), new_value <> "/" <> suffix} | @clears])
          end
        end
      end

      for {key, %{values: values}} <- @with_values do
        def merge_class(tailwind, new_value) when new_value in unquote(values) do
          Map.put(tailwind, unquote(key), new_value)
        end
      end

      for {key, %{prefix: prefix} = config} <-
            Enum.sort_by(@prefixed, fn {_, %{prefix: prefix}} ->
              -String.length(prefix)
            end) do
        if config[:naked?] do
          def merge_class(tailwind, unquote(prefix)) do
            Map.put(tailwind, unquote(key), "")
          end
        end

        unless config[:no_arbitrary?] do
          def merge_class(tailwind, unquote(prefix) <> "-" <> "[" <> _ = value_without_suffix) do
            unquote(prefix) <> "-" <> new_value = value_without_suffix
            Map.put(tailwind, unquote(key), new_value)
          end
        end

        if config[:digits?] do
          def merge_class(tailwind, unquote(prefix) <> "-px") do
            Map.put(tailwind, unquote(key), "px")
          end

          def merge_class(tailwind, unquote(prefix) <> "-" <> <<digit::binary-size(1)>> <> rest)
              when digit in @digits do
            Map.put(tailwind, unquote(key), "#{digit}#{rest}")
          end
        else
          def merge_class(tailwind, unquote(prefix) <> "-" <> new_value) do
            Map.put(tailwind, unquote(key), new_value)
          end
        end
      end

      for {class, %{prefix: string_class} = config} <- @directional do
        @dirs %{
          x: [:r, :l],
          y: [:t, :b],
          t: [:tl, :tr],
          r: [:tr, :br],
          b: [:br, :bl],
          l: [:tl, :bl]
        }

        for {dir, clears} <- @dirs do
          string_dir =
            if config[:dash_suffix?] do
              "-" <> to_string(dir)
            else
              to_string(dir)
            end

          @clears Enum.map(clears, &{&1, nil})

          if config[:values] do
            @values config[:values]
            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-" <> value
                )
                when value in @values do
              Map.put(tailwind, unquote(class), struct(Directions, %{unquote(dir) => value}))
            end
          end

          unless config[:no_arbitrary?] do
            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-[" <> rest
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(Directions, %{unquote(dir) => "[#{rest}"})
              )
            end

            def merge_class(
                  %{unquote(class) => directions} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-[" <> rest
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(directions, [{unquote(dir), "[#{rest}"} | @clears])
              )
            end
          end

          if config[:naked?] do
            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir)
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(Directions, %{unquote(dir) => ""})
              )
            end
          end

          if config[:digits?] do
            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-px"
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(Directions, %{unquote(dir) => "px"})
              )
            end

            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-" <> <<digit::binary-size(1)>> <> rest
                )
                when digit in @digits do
              Map.put(
                tailwind,
                unquote(class),
                struct(Directions, %{unquote(dir) => "#{digit}#{rest}"})
              )
            end
          else
            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-" <> value
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(Directions, %{unquote(dir) => value})
              )
            end
          end

          if config[:negative?] do
            if config[:naked?] do
              def merge_class(
                    %{unquote(class) => nil} = tailwind,
                    "-" <>
                      unquote(string_class) <>
                      unquote(string_dir)
                  ) do
                Map.put(
                  tailwind,
                  unquote(class),
                  struct(Directions, %{unquote(dir) => "-"})
                )
              end
            end

            def merge_class(
                  %{unquote(class) => nil} = tailwind,
                  "-" <> unquote(string_class) <> unquote(string_dir) <> "-" <> value
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(Directions, %{unquote(dir) => "-" <> value})
              )
            end
          end

          if config[:values] do
            @values config[:values]
            def merge_class(
                  %{unquote(class) => directions} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <>
                    "-" <>
                    value
                )
                when value in @values do
              Map.put(
                tailwind,
                unquote(class),
                struct(directions, [{unquote(dir), value} | @clears])
              )
            end
          end

          if config[:naked?] do
            def merge_class(
                  %{unquote(class) => directions} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir)
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(directions, [{unquote(dir), ""} | @clears])
              )
            end
          end

          if config[:digits?] do
            def merge_class(
                  %{unquote(class) => directions} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-" <> <<digit::binary-size(1)>> <> rest
                )
                when digit in @digits do
              Map.put(
                tailwind,
                unquote(class),
                struct(directions, [{unquote(dir), "#{digit}#{rest}"} | @clears])
              )
            end
          else
            def merge_class(
                  %{unquote(class) => directions} = tailwind,
                  unquote(string_class) <>
                    unquote(string_dir) <> "-" <> value
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(directions, [{unquote(dir), value} | @clears])
              )
            end
          end

          if config[:negative?] do
            if config[:naked?] do
              def merge_class(
                    %{unquote(class) => directions} = tailwind,
                    "-" <> unquote(string_class) <> unquote(string_dir)
                  ) do
                Map.put(
                  tailwind,
                  unquote(class),
                  struct(directions, [{unquote(dir), "-"} | @clears])
                )
              end
            end

            def merge_class(
                  %{unquote(class) => directions} = tailwind,
                  "-" <> unquote(string_class) <> unquote(string_dir) <> "-" <> value
                ) do
              Map.put(
                tailwind,
                unquote(class),
                struct(directions, [{unquote(dir), "-" <> value} | @clears])
              )
            end
          end
        end
      end

      for {class, %{prefix: string_class} = config} <- @directional do
        if config[:values] do
          @values config[:values]
          def merge_class(
                tailwind,
                unquote(string_class) <> "-" <> value
              )
              when value in @values do
            Map.put(tailwind, unquote(class), %Directions{all: value})
          end
        end

        unless config[:no_arbitrary?] do
          def merge_class(
                tailwind,
                unquote(string_class) <> "-[" <> rest
              ) do
            Map.put(tailwind, unquote(class), %Directions{all: "[#{rest}"})
          end
        end

        if config[:negative?] do
          if config[:naked?] do
            def merge_class(tailwind, "-" <> unquote(string_class)) do
              Map.put(tailwind, unquote(class), %Directions{all: "-"})
            end
          end

          def merge_class(tailwind, "-" <> unquote(string_class) <> "-" <> value) do
            Map.put(tailwind, unquote(class), %Directions{all: "-" <> value})
          end
        end

        if config[:naked?] do
          def merge_class(tailwind, unquote(string_class)) do
            Map.put(tailwind, unquote(class), %Directions{all: ""})
          end
        end

        if config[:digits?] do
          def merge_class(
                tailwind,
                unquote(string_class) <> "-px"
              ) do
            Map.put(tailwind, unquote(class), %Directions{all: "px"})
          end

          def merge_class(
                tailwind,
                unquote(string_class) <> "-" <> <<digit::binary-size(1)>> <> rest
              )
              when digit in @digits do
            Map.put(tailwind, unquote(class), %Directions{all: "#{digit}#{rest}"})
          end
        else
          def merge_class(
                tailwind,
                unquote(string_class) <> "-" <> value
              ) do
            Map.put(tailwind, unquote(class), %Directions{all: value})
          end
        end
      end

      if @fallback_to_colors do
        for {key, %{prefix: prefix} = config} <-
              Enum.sort_by(@prefixed_with_colors, fn {_, %{prefix: prefix}} ->
                -String.length(prefix)
              end) do
          @clears Keyword.new(config[:clears] || [], &{&1, nil})

          def merge_class(tailwind, unquote(prefix) <> "-" <> value) do
            struct(tailwind, [{unquote(key), value} | @clears])
          end
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

      for modifier <- @variants do
        def remove(tailwind, unquote(modifier) <> ":" <> rest) do
          rest = String.split(rest, ":")
          last = List.last(rest)
          variants = :lists.droplast(rest)

          key = Enum.sort([unquote(modifier) | variants])

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
          Enum.map(@directional, fn {key, %{prefix: prefix} = config} ->
            directional(Map.get(tailwind, key), prefix, !!config[:dash_suffix?], tailwind.variant)
          end),
          @singletons
          |> Enum.filter(&Map.get(tailwind, &1))
          |> Enum.map(fn class ->
            simple(to_string(class), tailwind.variant)
          end),
          Enum.map(@prefixed_with_colors, fn {key, %{prefix: prefix} = config} ->
            prefix(prefix, Map.get(tailwind, key), tailwind.variant, false)
          end),
          Enum.map(@prefixed_with_values, fn {key, %{prefix: prefix} = config} ->
            prefix(prefix, Map.get(tailwind, key), tailwind.variant, config[:naked?])
          end),
          Enum.map(@prefixed, fn {key, %{prefix: prefix} = config} ->
            prefix(prefix, Map.get(tailwind, key), tailwind.variant, config[:naked?])
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
      defp prefix(prefix, empty, nil, true) when empty in ["", nil], do: [" ", prefix]
      defp prefix(prefix, value, nil, _), do: [" ", prefix, "-", value]

      defp prefix(prefix, empty, variant, true) when empty in ["", nil],
        do: [" ", variant, ":", prefix]

      defp prefix(prefix, value, variant, _), do: [" ", variant, ":", prefix, "-", value]

      defp directional(nil, _key, _, _), do: ""

      defp directional(
             %Directions{
               l: l,
               r: r,
               t: t,
               b: b,
               x: x,
               y: y,
               tl: tl,
               tr: tr,
               bl: bl,
               br: br,
               all: all
             },
             key,
             dash_suffix?,
             variant
           ) do
        [
          direction(all, nil, key, variant, dash_suffix?),
          direction(tl, "tl", key, variant, dash_suffix?),
          direction(tr, "tr", key, variant, dash_suffix?),
          direction(bl, "bl", key, variant, dash_suffix?),
          direction(br, "br", key, variant, dash_suffix?),
          direction(t, "t", key, variant, dash_suffix?),
          direction(b, "b", key, variant, dash_suffix?),
          direction(l, "l", key, variant, dash_suffix?),
          direction(r, "r", key, variant, dash_suffix?),
          direction(x, "x", key, variant, dash_suffix?),
          direction(y, "y", key, variant, dash_suffix?)
        ]
        |> Enum.filter(& &1)
      end

      defp direction(nil, _, _, _, _), do: ""

      defp direction("", suffix, prefix, nil, dash_suffix?),
        do: [" ", prefix, dash_suffix(suffix, dash_suffix?)]

      defp direction("-" <> value, suffix, prefix, nil, dash_suffix?),
        do: [" -", prefix, dash_suffix(suffix, dash_suffix?), "-", value]

      defp direction(value, suffix, prefix, nil, dash_suffix?),
        do: [" ", prefix, dash_suffix(suffix, dash_suffix?), "-", value]

      defp direction("-" <> value, suffix, prefix, variant, dash_suffix?),
        do: [" ", variant, ":-", prefix, dash_suffix(suffix, dash_suffix?), "-", value]

      defp direction(value, suffix, prefix, variant, dash_suffix?),
        do: [" ", variant, ":", prefix, dash_suffix(suffix, dash_suffix?), "-", value]

      defp dash_suffix(value, true) when not is_nil(value), do: ["-", value]
      defp dash_suffix(nil, _), do: ""
      defp dash_suffix(value, _), do: value

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

      # for {key, value} when is_map(value) <- @colors do
      #   for {suffix, value} when is_binary(value) <- value do
      #     if suffix == "DEFAULT" do
      #       # sobelow_skip ["DOS.BinToAtom"]
      #       def unquote(:"#{String.replace(key, "-", "_")}")() do
      #         unquote(value)
      #       end
      #     else
      #       # sobelow_skip ["DOS.BinToAtom"]
      #       def unquote(:"#{String.replace(key, "-", "_")}_#{String.replace(suffix, "-", "_")}")() do
      #         unquote(value)
      #       end
      #     end
      #   end
      # end
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
