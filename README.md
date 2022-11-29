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

This merge is a "allow-list" style merge, meaning classes that we haven't thought about and/or aren't aware of a good merge strategy are just added to the end of the class list.
There are tons of class combinations that could potentially be intelligently merged, so if you spot one that should be added just let us know!

See the module docs for `Tails` to see what we currently handle

## Colors

When working with LiveViewNative, or in-line-styling emails, for example, you will likely want access to your tailwind colors. However, tailwind won't work in those cases. To that end, you can configure a `colors.json` file, which you would also reference in your tailwind.config.

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


## Installation

This package is currently only available on github, as it is still experimental. 
