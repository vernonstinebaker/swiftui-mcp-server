# Swift

- Prefer Swift-native string methods over Foundation equivalents.
- Prefer modern Foundation API: URL.documentsDirectory instead of FileManager directory lookups.
- Never use C-style number formatting like String(format: "%.2f", value). Use FormatStyle APIs instead.
- Prefer static member lookup to struct instances where possible.
- Avoid force unwraps and force try unless the failure is truly unrecoverable.
- Filtering text based on user-input must be done using localizedStandardContains().
- Strongly prefer Double over CGFloat, except when using optionals or inout.
- If you want to count array objects that match a predicate, always use count(where:) rather than filter() followed by count.
- Prefer Date.now over Date() for clarity.
- When import SwiftUI is already in a file, you do not need to add import UIKit or import AppKit.
- When dealing with the names of people, strongly prefer to use PersonNameComponents with modern formatting.
- If a given type of data is repeatedly sorted using an identical closure, prefer to make the type conform to Comparable.
- Prefer to avoid manual date formatting strings if possible. Use "y" rather than "yyyy" for years in user-facing display.
- When trying to convert a string to a date, prefer Date(myString, strategy: .iso8601).
- Flag instances where errors triggered by a user action are swallowed silently.
- Prefer if let value { shorthand over if let value = value {.
- Omit return for single expression functions. if and switch can be used as expressions.

## Swift Concurrency

- Always prefer async/await over older closure-based variants.
- Never use Grand Central Dispatch. Always use modern Swift concurrency.
- Never use Task.sleep(nanoseconds:); use Task.sleep(for:) instead.
- Flag any mutable shared state that is not protected by an actor or @MainActor.
- Assume strict concurrency rules are being applied; flag @Sendable violations and data races.
- Task.detached() is often a bad idea. Check any usage extremely carefully.
