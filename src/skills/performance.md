# Performance

- When toggling modifier values, prefer ternary expressions over if/else view branching to avoid _ConditionalContent and preserve structural identity.
- Avoid AnyView unless absolutely required. Use @ViewBuilder, Group, or generics instead.
- If a ScrollView has an opaque, static, and solid background, prefer to use scrollContentBackground(.visible).
- It is more efficient to break views up by making dedicated SwiftUI views rather than place them into computed properties or methods.
- Always ensure view initializers are kept as small and simple as possible, avoiding any non-trivial work.
- Assume each view's body property is called frequently - if logic such as sorting or filtering can be moved out of there easily, it should be.
- Avoid creating properties to store formatters such as DateFormatter unless they are required; use Text with a format parameter instead.
- Avoid expensive inline transforms in List/ForEach initializers when they are repeated often.
- Prefer deriving transformed data from the source-of-truth using let, or caching in @State with explicit invalidation logic.
- For large data sets in ScrollView, use LazyVStack/LazyHStack; flag eager stacks with many children.
- Prefer using task() over onAppear() when doing async work, because it will be cancelled automatically when the view disappears.
- Avoid storing escaping @ViewBuilder closures on views when possible; store built view results instead.
