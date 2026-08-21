import SwiftUI

// MARK: - What the Mac has not got

#if os(macOS)
/// `fullScreenCover`, for a platform that has no full screen to cover.
///
/// The app ships on iOS. The Mac build exists so the tests can run without a
/// simulator — headless, in a few seconds, on every change — and that build has
/// to compile the screens even though nobody looks at them on a Mac.
///
/// SwiftUI marks `fullScreenCover` unavailable on macOS, so every screen that
/// presents the paywall broke the Mac build, and with it the whole test suite:
/// fourteen call sites across nine files, all of them the same call. The
/// alternative was fourteen `#if os(iOS)` blocks — the same fix written out
/// fourteen times, and a fifteenth waiting for whoever adds the next screen.
///
/// A sheet is what a Mac would use anyway.
public extension View {
    func fullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
    }

    func fullScreenCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item, onDismiss: onDismiss, content: content)
    }
}
#endif
