import ChessCore
import Foundation

/// Text the training layer produces for the player to read.
///
/// Kept behind explicit keys rather than left as literals, because a sentence
/// this layer builds — "Black to play", "Mate in 3" — is shown on screen just
/// as much as anything in a view, and a phrase assembled from English fragments
/// cannot be translated at all: word order is not a detail other languages
/// agree with us about.
public enum L {
    /// Looks the key up in the app's bundle, falling back to the English source
    /// when there is no catalog — which is what happens in the test bundle, and
    /// what happens for any string a translator has not reached yet.
    ///
    /// `Bundle.localizedString(forKey:)` rather than `String(localized:)`
    /// because the latter wants a compile-time literal, and these keys are
    /// passed around as values.
    public static func t(_ key: String, _ english: String) -> String {
        Bundle.main.localizedString(forKey: key, value: english, table: nil)
    }

    public static func t(_ key: String, _ english: String, _ arguments: CVarArg...) -> String {
        String(format: t(key, english), arguments: arguments)
    }

    public static func color(_ color: PieceColor) -> String {
        color == .white ? t("color.white", "White") : t("color.black", "Black")
    }
}
