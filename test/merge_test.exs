# MIT License
#
# Copyright (c) 2021 Dany Castillo
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Notice
# This was copied almost literally from https://github.com/leuchtturm-dev/turboprop
# That, in turn, was copied from tailwind_merge authored by Dany Castillo
# Thank you to everyone involved :)

defmodule Turboprop.MergeTest do
  use ExUnit.Case, async: false

  describe "non-conflicting" do
    test "merges non-conflicting classes correctly" do
      assert Tails.classes(["border-t", "border-white/10"]) == "border-white/10 border-t"
      assert Tails.classes(["border-t", "border-white"]) == "border-white border-t"
      assert Tails.classes(["text-3.5xl", "text-black"]) == "text-black text-3.5xl"
    end
  end

  describe "colors" do
    test "handles color conflicts properly" do
      assert Tails.classes("bg-gray-50 bg-teal-100") == "bg-teal-100"
      assert Tails.classes("hover:bg-gray-50 hover:bg-teal-100") == "hover:bg-teal-100"

      assert Tails.classes(["stroke-[hsl(350_80%_0%)]", "stroke-[10px]"]) ==
               "stroke-[hsl(350_80%_0%)] stroke-[10px]"
    end
  end

  describe "borders" do
    test "merges classes with per-side border colors correctly" do
      assert Tails.classes(["border-t-some-blue", "border-t-other-blue"]) == "border-t-other-blue"
      assert Tails.classes(["border-t-some-blue", "border-some-blue"]) == "border-some-blue"
    end
  end

  describe "group conflicts" do
    test "merges classes from same group correctly" do
      assert Tails.classes("overflow-x-auto overflow-x-hidden") == "overflow-x-hidden"
      assert Tails.classes("basis-full basis-auto") == "basis-auto"
      assert Tails.classes("w-full w-fit") == "w-fit"

      assert Tails.classes("overflow-x-auto overflow-x-hidden overflow-x-scroll") ==
               "overflow-x-scroll"

      assert Tails.classes(["overflow-x-auto", "hover:overflow-x-hidden", "overflow-x-scroll"]) ==
               "overflow-x-scroll hover:overflow-x-hidden"

      assert Tails.classes([
               "overflow-x-auto",
               "hover:overflow-x-hidden",
               "hover:overflow-x-auto",
               "overflow-x-scroll"
             ]) ==
               "overflow-x-scroll hover:overflow-x-auto"

      assert Tails.classes("col-span-1 col-span-full") == "col-span-full"
    end

    test "merges classes from Font Variant Numeric section correctly" do
      assert Tails.classes(["lining-nums", "tabular-nums", "diagonal-fractions"]) ==
               "lining-nums tabular-nums diagonal-fractions"

      assert Tails.classes(["normal-nums", "tabular-nums", "diagonal-fractions"]) ==
               "tabular-nums diagonal-fractions"

      assert Tails.classes(["tabular-nums", "diagonal-fractions", "normal-nums"]) == "normal-nums"
      assert Tails.classes("tabular-nums proportional-nums") == "proportional-nums"
    end
  end

  describe "conflicts across groups" do
    test "handles conflicts across class groups correctly" do
      assert Tails.classes("inset-1 inset-x-1") == "inset-1 inset-x-1"
      assert Tails.classes("inset-x-1 inset-1") == "inset-1"
      assert Tails.classes(["inset-x-1", "left-1", "inset-1"]) == "inset-1"
      assert Tails.classes(["inset-x-1", "inset-1", "left-1"]) == "inset-1 left-1"
      assert Tails.classes(["inset-x-1", "right-1", "inset-1"]) == "inset-1"
      assert Tails.classes(["inset-x-1", "right-1", "inset-x-1"]) == "inset-x-1"
      assert Tails.classes(["inset-x-1", "right-1", "inset-y-1"]) == "inset-x-1 right-1 inset-y-1"
      assert Tails.classes(["right-1", "inset-x-1", "inset-y-1"]) == "inset-x-1 inset-y-1"
      assert Tails.classes(["inset-x-1", "hover:left-1", "inset-1"]) == "hover:left-1 inset-1"
    end

    test "ring and shadow classes do not create conflict" do
      assert Tails.classes(["ring", "shadow"]) == "shadow ring"
      assert Tails.classes(["ring-2", "shadow-md"]) == "shadow-md ring-2"
      assert Tails.classes(["shadow", "ring"]) == "shadow ring"
      assert Tails.classes(["shadow-md", "ring-2"]) == "shadow-md ring-2"
    end

    test "touch classes do create conflicts correctly" do
      assert Tails.classes("touch-pan-x touch-pan-right") == "touch-pan-right"
      assert Tails.classes("touch-none touch-pan-x") == "touch-pan-x"
      assert Tails.classes("touch-pan-x touch-none") == "touch-none"

      assert Tails.classes(["touch-pan-x", "touch-pan-y", "touch-pinch-zoom"]) ==
               "touch-pan-x touch-pan-y touch-pinch-zoom"

      assert Tails.classes([
               "touch-manipulation",
               "touch-pan-x",
               "touch-pan-y",
               "touch-pinch-zoom"
             ]) ==
               "touch-pan-x touch-pan-y touch-pinch-zoom"

      assert Tails.classes(["touch-pan-x", "touch-pan-y", "touch-pinch-zoom", "touch-auto"]) ==
               "touch-auto"
    end

    test "line-clamp classes do create conflicts correctly" do
      assert Tails.classes(["overflow-auto", "inline", "line-clamp-1"]) == "line-clamp-1"

      assert Tails.classes(["line-clamp-1", "overflow-auto", "inline"]) ==
               "line-clamp-1 overflow-auto inline"
    end
  end

  describe "arbitrary values" do
    test "handles simple conflicts with arbitrary values correctly" do
      # assert Tails.classes("m-[2px] m-[10px]") == "m-[10px]"

      # assert Tails.classes([
      #          "m-[2px]",
      #          "m-[11svmin]",
      #          "m-[12in]",
      #          "m-[13lvi]",
      #          "m-[14vb]",
      #          "m-[15vmax]",
      #          "m-[16mm]",
      #          "m-[17%]",
      #          "m-[18em]",
      #          "m-[19px]",
      #          "m-[10dvh]"
      #        ]) == "m-[10dvh]"

      # assert Tails.classes([
      #          "h-[10px]",
      #          "h-[11cqw]",
      #          "h-[12cqh]",
      #          "h-[13cqi]",
      #          "h-[14cqb]",
      #          "h-[15cqmin]",
      #          "h-[16cqmax]"
      #        ]) == "h-[16cqmax]"

      # assert Tails.classes("z-20 z-[99]") == "z-[99]"
      # assert Tails.classes("my-[2px] m-[10rem]") == "m-[10rem]"
      # assert Tails.classes("cursor-pointer cursor-[grab]") == "cursor-[grab]"

      # assert Tails.classes("m-[2px] m-[calc(100%-var(--arbitrary))]") ==
      #          "m-[calc(100%-var(--arbitrary))]"

      # assert Tails.classes("m-[2px] m-[length:var(--mystery-var)]") ==
      #          "m-[length:var(--mystery-var)]"

      assert Tails.classes("opacity-10 opacity-[0.025]") == "opacity-[0.025]"
      # assert Tails.classes("scale-75 scale-[1.7]") == "scale-[1.7]"
      # assert Tails.classes("brightness-90 brightness-[1.75]") == "brightness-[1.75]"
      # assert Tails.classes("min-h-[0.5px] min-h-[0]") == "min-h-[0]"
      # assert Tails.classes("text-[0.5px] text-[color:0]") == "text-[0.5px] text-[color:0]"
      # assert Tails.classes("text-[0.5px] text-[--my-0]") == "text-[0.5px] text-[--my-0]"
    end

    test "handles arbitrary length conflicts with labels and modifiers correctly" do
      assert Tails.classes("hover:m-[2px] hover:m-[length:var(--c)]") ==
               "hover:m-[length:var(--c)]"

      assert Tails.classes("hover:focus:m-[2px] focus:hover:m-[length:var(--c)]") ==
               "focus:hover:m-[length:var(--c)]"

      assert Tails.classes("border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]") ==
               "border-b border-[color:rgb(var(--color-gray-500-rgb)/50%))]"

      assert Tails.classes("border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-b") ==
               "border-[color:rgb(var(--color-gray-500-rgb)/50%))] border-b"

      assert Tails.classes([
               "border-b",
               "border-[color:rgb(var(--color-gray-500-rgb)/50%))]",
               "border-some-coloooor"
             ]) ==
               "border-b border-some-coloooor"
    end

    test "handles complex arbitrary value conflicts correctly" do
      assert Tails.classes("grid-rows-[1fr,auto] grid-rows-2") == "grid-rows-2"
      assert Tails.classes("grid-rows-[repeat(20,minmax(0,1fr))] grid-rows-3") == "grid-rows-3"
    end

    test "handles ambiguous arbitrary values correctly" do
      assert Tails.classes("mt-2 mt-[calc(theme(fontSize.4xl)/1.125)]") ==
               "mt-[calc(theme(fontSize.4xl)/1.125)]"

      assert Tails.classes("p-2 p-[calc(theme(fontSize.4xl)/1.125)_10px]") ==
               "p-[calc(theme(fontSize.4xl)/1.125)_10px]"

      assert Tails.classes("mt-2 mt-[length:theme(someScale.someValue)]") ==
               "mt-[length:theme(someScale.someValue)]"

      assert Tails.classes("mt-2 mt-[theme(someScale.someValue)]") ==
               "mt-[theme(someScale.someValue)]"

      assert Tails.classes("text-2xl text-[length:theme(someScale.someValue)]") ==
               "text-[length:theme(someScale.someValue)]"

      assert Tails.classes("text-2xl text-[calc(theme(fontSize.4xl)/1.125)]") ==
               "text-[calc(theme(fontSize.4xl)/1.125)]"

      assert Tails.classes(["bg-cover", "bg-[percentage:30%]", "bg-[length:200px_100px]"]) ==
               "bg-[length:200px_100px]"

      assert Tails.inspect_debug(Tails.classes([
               "bg-none",
               "bg-[url(.)]",
               "bg-[image:.]",
               "bg-[url:.]",
               "bg-[linear-gradient(.)]",
               "bg-gradient-to-r"
             ])) ==
               "bg-gradient-to-r"
    end
  end

  describe "arbitrary properties" do
    test "handles arbitrary property conflicts correctly" do
      assert Tails.classes("[paint-order:markers] [paint-order:normal]") == "[paint-order:normal]"

      assert Tails.classes([
               "[paint-order:markers]",
               "[--my-var:2rem]",
               "[paint-order:normal]",
               "[--my-var:4px]"
             ]) ==
               "[--my-var:4px] [paint-order:normal]"
    end

    test "handles arbitrary property conflicts with modifiers correctly" do
      assert Tails.classes("[paint-order:markers] hover:[paint-order:normal]") ==
               "[paint-order:markers] hover:[paint-order:normal]"

      assert Tails.classes("hover:[paint-order:markers] hover:[paint-order:normal]") ==
               "hover:[paint-order:normal]"

      assert Tails.classes("hover:focus:[paint-order:markers] focus:hover:[paint-order:normal]") ==
               "focus:hover:[paint-order:normal]"

      assert Tails.classes([
               "[paint-order:markers]",
               "[paint-order:normal]",
               "[--my-var:2rem]",
               "lg:[--my-var:4px]"
             ]) ==
               "[paint-order:normal] [--my-var:2rem] lg:[--my-var:4px]"
    end

    test "handles complex arbitrary property conflicts correctly" do
      assert Tails.classes("[-unknown-prop:::123:::] [-unknown-prop:url(https://hi.com)]") ==
               "[-unknown-prop:url(https://hi.com)]"
    end

    test "handles important modifier correctly" do
      assert Tails.classes("![some:prop] [some:other]") == "![some:prop] [some:other]"

      assert Tails.classes("![some:prop] [some:other] [some:one] ![some:another]") ==
               "[some:one] ![some:another]"
    end
  end

  describe "pseudo variants" do
    test "handles pseudo variants conflicts properly" do
      assert Tails.classes(["empty:p-2", "empty:p-3"]) == "empty:p-3"
      assert Tails.classes(["hover:empty:p-2", "hover:empty:p-3"]) == "hover:empty:p-3"
      assert Tails.classes(["read-only:p-2", "read-only:p-3"]) == "read-only:p-3"
    end

    test "handles pseudo variant group conflicts properly" do
      assert Tails.classes(["group-empty:p-2", "group-empty:p-3"]) == "group-empty:p-3"
      assert Tails.classes(["peer-empty:p-2", "peer-empty:p-3"]) == "peer-empty:p-3"

      assert Tails.classes(["group-empty:p-2", "peer-empty:p-3"]) ==
               "group-empty:p-2 peer-empty:p-3"

      assert Tails.classes(["hover:group-empty:p-2", "hover:group-empty:p-3"]) ==
               "hover:group-empty:p-3"

      assert Tails.classes(["group-read-only:p-2", "group-read-only:p-3"]) ==
               "group-read-only:p-3"
    end
  end

  describe "arbitrary variants" do
    test "basic arbitrary variants" do
      assert Tails.classes("[&>*]:underline [&>*]:line-through") == "[&>*]:line-through"

      assert Tails.classes(["[&>*]:underline", "[&>*]:line-through", "[&_div]:line-through"]) ==
               "[&>*]:line-through [&_div]:line-through"

      assert Tails.classes("supports-[display:grid]:flex supports-[display:grid]:grid") ==
               "supports-[display:grid]:grid"
    end

    test "arbitrary variants with modifiers" do
      assert Tails.classes("dark:lg:hover:[&>*]:underline dark:lg:hover:[&>*]:line-through") ==
               "[&>*]:dark:hover:lg:line-through"

      assert Tails.classes("dark:lg:hover:[&>*]:underline dark:hover:lg:[&>*]:line-through") ==
               "[&>*]:dark:hover:lg:line-through"

      assert Tails.classes("hover:[&>*]:underline [&>*]:hover:line-through") ==
               "hover:[&>*]:underline [&>*]:hover:line-through"

      assert Tails.classes([
               "hover:dark:[&>*]:underline",
               "dark:hover:[&>*]:underline",
               "dark:[&>*]:hover:line-through"
             ]) ==
               "dark:hover:[&>*]:underline dark:[&>*]:hover:line-through"
    end

    test "arbitrary variants with complex syntax in them" do
      assert Tails.classes([
               "[@media_screen{@media(hover:hover)}]:underline",
               "[@media_screen{@media(hover:hover)}]:line-through"
             ]) ==
               "[@media_screen{@media(hover:hover)}]:line-through"

      assert Tails.classes(
               "hover:[@media_screen{@media(hover:hover)}]:underline hover:[@media_screen{@media(hover:hover)}]:line-through"
             ) ==
               "hover:[@media_screen{@media(hover:hover)}]:line-through"
    end

    test "arbitrary variants with attribute selectors" do
      assert Tails.classes("[&[data-open]]:underline [&[data-open]]:line-through") ==
               "[&[data-open]]:line-through"
    end

    test "arbitrary variants with multiple attribute selectors" do
      assert Tails.classes([
               "[&[data-foo][data-bar]:not([data-baz])]:underline",
               "[&[data-foo][data-bar]:not([data-baz])]:line-through"
             ]) ==
               "[&[data-foo][data-bar]:not([data-baz])]:line-through"
    end

    test "multiple arbitrary variants" do
      assert Tails.classes("[&>*]:[&_div]:underline [&>*]:[&_div]:line-through") ==
               "[&>*]:[&_div]:line-through"

      assert Tails.classes(["[&>*]:[&_div]:underline", "[&_div]:[&>*]:line-through"]) ==
               "[&>*]:[&_div]:underline [&_div]:[&>*]:line-through"

      assert Tails.classes([
               "hover:dark:[&>*]:focus:disabled:[&_div]:underline",
               "hover:dark:[&>*]:focus:disabled:[&_div]:line-through"
             ]) ==
               "hover:dark:[&>*]:focus:disabled:[&_div]:line-through"

      assert Tails.classes([
               "hover:dark:[&>*]:focus:[&_div]:disabled:underline",
               "hover:dark:[&>*]:focus:[&_div]:disabled:line-through"
             ]) ==
               "hover:dark:[&>*]:focus:[&_div]:disabled:line-through"
    end

    test "arbitrary variants with arbitrary properties" do
      assert Tails.classes("[&>*]:[color:red] [&>*]:[color:blue]") == "[&>*]:[color:blue]"

      assert Tails.classes([
               "[&[data-foo][data-bar]:not([data-baz])]:nod:noa:[color:red]",
               "[&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue]"
             ]) ==
               "[&[data-foo][data-bar]:not([data-baz])]:noa:nod:[color:blue] [&[data-foo][data-bar]:not([data-baz])]:nod:noa:[color:red]"
    end
  end

  describe "content utilities" do
    test "merges content utilities correctly" do
      assert Tails.classes(["content-['hello']", "content-[attr(data-content)]"]) ==
               "content-[attr(data-content)]"
    end
  end

  describe "important modifier" do
    test "merges tailwind classes with important modifier correctly" do
      assert Tails.classes(["!font-medium", "!font-bold"]) == "!font-bold"
      assert Tails.classes(["!font-medium", "!font-bold", "font-thin"]) == "!font-bold font-thin"
      assert Tails.classes(["!right-2", "!-inset-x-px"]) == "!-inset-x-px"
      assert Tails.classes(["focus:!inline", "focus:!block"]) == "focus:!block"
    end
  end

  describe "modifiers" do
    test "conflicts across prefix modifiers" do
      assert Tails.classes("hover:block hover:inline") == "hover:inline"

      assert Tails.classes(["hover:block", "hover:focus:inline"]) ==
               "hover:block hover:focus:inline"

      assert Tails.classes(["hover:block", "hover:focus:inline", "focus:hover:inline"]) ==
               "hover:block focus:hover:inline"

      assert Tails.classes("focus-within:inline focus-within:block") == "focus-within:block"
    end

    test "conflicts across postfix modifiers" do
      assert Tails.classes("text-lg/7 text-lg/8") == "text-lg/8"
      assert Tails.classes(["text-lg/none", "leading-9"]) == "text-lg/none leading-9"
      assert Tails.classes(["leading-9", "text-lg/none"]) == "text-lg/none"
      assert Tails.classes("w-full w-1/2") == "w-1/2"
    end
  end

  describe "negative values" do
    test "handles negative value conflicts correctly" do
      assert Tails.classes(["-m-2", "-m-5"]) == "-m-5"
      assert Tails.classes(["-top-12", "-top-2000"]) == "-top-2000"
    end

    test "handles conflicts between positive and negative values correctly" do
      assert Tails.classes(["-m-2", "m-auto"]) == "m-auto"
      assert Tails.classes(["top-12", "-top-69"]) == "-top-69"
    end

    test "handles conflicts across groups with negative values correctly" do
      assert Tails.classes(["-right-1", "inset-x-1"]) == "inset-x-1"

      assert Tails.classes(["hover:focus:-right-1", "focus:hover:inset-x-1"]) ==
               "focus:hover:inset-x-1"
    end
  end

  describe "non-tailwind" do
    test "does not alter non-tailwind classes" do
      assert Tails.classes(["non-tailwind-class", "inline", "block"]) ==
               "block non-tailwind-class"

      assert Tails.classes(["inline", "block", "inline-1"]) == "block inline-1"
      assert Tails.classes(["inline", "block", "i-inline"]) == "block i-inline"

      assert Tails.classes(["focus:inline", "focus:block", "focus:inline-1"]) ==
               "focus:block focus:inline-1"
    end
  end
end
