internal import SwiftUI

/// Minimal + typographic styling helpers (Option B).
enum AppStyle {
    static var screenBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.black.opacity(0.0)
        #endif
    }

    static var cardBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.white.opacity(0.04)
        #endif
    }

    static var subtleFill: Color {
        #if os(iOS)
        return Color(UIColor.tertiarySystemFill)
        #elseif os(macOS)
        return Color(NSColor.tertiaryLabelColor).opacity(0.12)
        #else
        return Color.white.opacity(0.08)
        #endif
    }

    static var cardCornerRadius: CGFloat { 16 }
}

struct AppSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .padding(.top, 4)
    }
}

extension View {
    func appScreenBackground() -> some View {
        background(AppStyle.screenBackground)
    }

    func appScrollBackground() -> some View {
        background(AppStyle.screenBackground.ignoresSafeArea())
    }

    func appCard(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius, style: .continuous)
                    .fill(AppStyle.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }

    /// Makes a `List` look modern/minimal by hiding the default background.
    func appListContainer() -> some View {
        self
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #endif
            .listStyle(.plain)
            .background(AppStyle.screenBackground)
    }

    /// Makes a `Form` blend with the app background across iOS/macOS.
    func appFormContainer() -> some View {
        self
            #if os(iOS)
            .scrollContentBackground(.hidden)
            #endif
            .background(AppStyle.screenBackground)
    }

    /// Applies card-like row styling inside a `List` row.
    func appListRowCard() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    func appSectionTitleRow() -> some View {
        self
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 2, trailing: 0))
    }
}

struct AppCardPressedHighlightStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.14 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius, style: .continuous)
                    .stroke(Color.accentColor.opacity(configuration.isPressed ? 0.55 : 0), lineWidth: 1)
            )
    }
}
