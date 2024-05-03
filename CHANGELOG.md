# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.1.11](https://github.com/zachdaniel/tails/compare/v0.1.10...v0.1.11) (2024-05-03)




### Improvements:

* support `color_classes` config

## [v0.1.10](https://github.com/zachdaniel/tails/compare/v0.1.9...v0.1.10) (2024-03-04)




### Bug Fixes:

* include px in numeric scale

* Missing 5 in digits (#18)

## [v0.1.9](https://github.com/zachdaniel/tails/compare/v0.1.8...v0.1.9) (2024-02-20)




### Bug Fixes:

* properly merge directional classes with dashes before the directions

* don't sort variants

* various typos and better prefix merging

### Improvements:

* better behavior with unknown custom colors

## [v0.1.8](https://github.com/zachdaniel/tails/compare/v0.1.7...v0.1.8) (2023-11-21)




### Bug Fixes:

* identify and merge known custom color values only

### Improvements:

* add `~t` sigil

## [v0.1.7](https://github.com/zachdaniel/tails/compare/v0.1.6...v0.1.7) (2023-08-26)




### Bug Fixes:

* handle color opacity suffixes

## [v0.1.6](https://github.com/zachdaniel/tails/compare/v0.1.5...v0.1.6) (2023-07-21)




### Bug Fixes:

* shadows merge (#10)

### Improvements:

* remove colors that don't exist in tailwind spec

* massively speed up compile times for color classes

* support deeply-nested theme colors (#7)

## [v0.1.5](https://github.com/zachdaniel/tails/compare/v0.1.4...v0.1.5) (2023-04-30)




### Bug Fixes:

* partial update and bugfixes (#5)

* border-separate typo

* properly handle naked prefixed values

* handle naked prefixed values

## [v0.1.4](https://github.com/zachdaniel/tails/compare/v0.1.3...v0.1.4) (2023-03-01)




### Bug Fixes:

* do simple prefixes after directional, add doctest

* do directional matching after prefixed matching

* don't double-add prefix for arbitrary values

## [v0.1.3](https://github.com/zachdaniel/tails/compare/v0.1.2...v0.1.3) (2022-12-28)




### Improvements:

* flesh out remaining classes, fix directional merging

* automatic dark theme construction

* col-span-*

## [v0.1.2](https://github.com/zachdaniel/tails/compare/v0.1.1...v0.1.2) (2022-12-22)




### Improvements:

* support themes being set as strings

## [v0.1.1](https://github.com/zachdaniel/tails/compare/v0.1.0...v0.1.1) (2022-12-20)




### Bug Fixes:

* we can't split directionals because tailwind won't see them anymore

### Improvements:

* fallback to default theme

* various improvements to configuration & theming

* custom tails modules

* support themes

* add all builtin colors and colors from tailwind config

## [v0.1.0](https://github.com/zachdaniel/tails/compare/v0.1.0...v0.1.0) (2022-12-20)




### Features:

* add `grid-cols-` and `grid-rows-` (#1)

### Bug Fixes:

* handle empty class lists

* missing - for `x` directions

* `classes` returns strings, `merge` returns a `%Tails{}`

### Improvements:

* get ready for publishing

* handle tlbr classes properly

* optional `optimize_directions?` config

* fix some bugs around bg- and text- prefixes

* add display and position merging

* add to readme
