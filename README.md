# Tails

Tails is a small set of utilities around working with tailwind class lists in Elixir.

# Utilities

## Classes

Classes takes a list of class lists or conditional class lists and returns a single class list. For example:

```elixir
classes(["foo", "bar"])
# "foo bar"
classes(["foo": false, "bar": true])
# "bar"
```

Class lists are merged from right to left (i.e left is the base, right is the override). See the section on merging below

## Merge

Merge takes a list of classes and semantically merges any tailwind classes it knows about, leaving the rest untouched. The first argument is treated as a base, and the second argument is treated as overrides.

For example
```elixir
iex> merge("p-4", "p-2") |> to_string()
"p-2"
iex> merge("p-2", "p-4") |> to_string()
"p-4"
iex> merge("p-4", "px-2") |> to_string()
"px-2 py-4"
iex> merge("font-bold", "font-thin") |> to_string()
"font-thin"
iex> merge("font-normal text-black hover:text-primary-light-300", "text-primary-600 dark:text-primary-dark-400 font-bold") |> to_string()
"font-bold text-primary-600 dark:text-primary-dark-400 hover:text-primary-light-300"
```

This merge is a "allow-list" style merge, meaning classes that we haven't thought about and/or aren't aware of a good merge strategy are just added to the end of the class list. We should have covered the tailwind spec pretty well as of March 2023.

See the module docs for `Tails` to see what we currently handle

### Configuration

#### No Merge Classes

Set `config :tails, :no_merge_classes, [:foo, :bar]` to avoid merging a specific set of classes. Can be useful as an escape hatch if tails is doing the wrong thing.

## Colors

We use custom defined colors for two things:

1. providing class name helpers for use in other contexts
2. merging custom color values, for example so that we know that adding `bg-specialred` should remove `bg-specialblue`.

If you *don't* do this, there are certain cases that we are currently unable to disambiguate. For example, if you have a custom font size utility, i.e `text-really-big` and a custom color utility, used like `text-really-red`, we can't tell which is which. We don't guarantee the behavior of that combination, but as of the writing of this paragraph, they will both override the font size.

I highly suggest that you configure your colors file statically, or configure your colors by hand as explained below if you want to use tails *or* help us figure out a way to make it unnecessary, because I can't think of one :)

## Configuring custom colors without a colors file

You can configure custom colors without a colors file by setting the following configuration:

```elixir
config :tails, :color_classes, ["primary", "secondary", ...]
```

or if using a custom tails module

```elixir
config :my_app, Tails,
  color_classes: ["primary", "secondary", ...]
```

## Merging Custom Colors

*IF* you follow the steps outlined in the setup section below, then that is all you need to do for this. *IF NOT* you should set the following configuration if you are using any custom colors, keeping in mind that there are cases we won't be able to tell the difference between currently (as noted above).

```elixir
config :tails, :fallback_to_colors, true
```

## Class Name Helpers

When working with LiveViewNative, or in-line-styling emails, for example, you will likely want access to your tailwind colors even though tailwind css is not available.


## Setup

To tell tails about your colors, create a `colors.json` file, which you would also reference in your tailwind.config.

Then, `Tails` would define a function for each color.

```elixir
# in config.exs
config :tails, colors_file: Path.join(File.cwd!(), "assets/tailwind.colors.json")
```

```js
// in tailwind.config.js
module.exports = {
  mode: "jit",
  content: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  darkMode: "class",
  theme: {
    extend: {
      colors: require("./tailwind.colors.json")
    },
  }
};
```

```json
// in tailwind.colors.json
{
  "silver-phoenix": "#EAEBF3",
  "base-dark": {
    "DEFAULT": "#5E627D",
    "50": "#C2C4D1",
    ...
  },
  ...
}
```

This would define `Tails.silver_phoenix()`, `Tails.base_dark()` and `Tails.base_dark_50()`, which return the respective hash code colors.
