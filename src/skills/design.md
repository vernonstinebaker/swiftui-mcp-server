# Design

## Creating a uniform design in this app

Prefer to place standard fonts, sizes, colors, stack spacing, padding, rounding, animation timings, and more into a shared enum of constants, so they can be used by all views.

## Requirements for flexible, accessible design

- Never use `UIScreen.main.bounds` to read available space; prefer alternatives such as `containerRelativeFrame()`, or `visualEffect()` as appropriate.
- Prefer to avoid fixed frames for views unless content can fit neatly inside.
- Apple's minimum acceptable tap area for interactions on iOS is 44x44. Ensure this is strictly enforced.

## Standard system styling

- Strongly prefer to use `ContentUnavailableView` when data is missing or empty, rather than designing something custom.
- When using `searchable()`, you can show empty results using `ContentUnavailableView.search` and it will include the search term automatically.
- If you need an icon and some text placed horizontally side by side, prefer `Label` over `HStack`.
- Prefer system hierarchical styles (e.g. secondary/tertiary) over manual opacity when possible.
- When using `Form`, wrap controls such as `Slider` in `LabeledContent` so the title and control are laid out correctly.
- When using `RoundedRectangle`, the default rounding style is `.continuous` - there is no need to specify it explicitly.

## Ensuring designs work for everyone

- Use `bold()` instead of `fontWeight(.bold)`, because using `bold()` allows the system to choose the correct weight for the current context.
- Only use `fontWeight()` for weights other than bold when there's an important reason.
- Avoid hard-coded values for padding and stack spacing unless specifically requested.
- Avoid UIKit colors (`UIColor`) in SwiftUI code; use SwiftUI `Color` or asset catalog colors.
- The font size `.caption2` is extremely small, and is generally best avoided.