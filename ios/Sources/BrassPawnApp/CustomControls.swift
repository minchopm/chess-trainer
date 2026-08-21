import ChessCore
import SwiftUI

/// Back, in whichever direction back is.
///
/// `chevron.backward` rather than `chevron.left`: the two draw the same glyph
/// in English and only one of them turns round for a language that reads
/// right to left. In Hebrew or Arabic the button sits on the right of the bar
/// and pointed left anyway, which is an arrow aimed at the rest of the screen.
struct BrassBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theatre.brassHot)
                .frame(width: 44, height: 44)
                .background {
                    Circle().fill(LinearGradient(
                        colors: [Theatre.ink4, Theatre.ink2],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                }
                .overlay {
                    Circle()
                        .strokeBorder(Theatre.brassDeep.opacity(0.7), lineWidth: 0.8)
                }
                .contentShape(Circle())
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel("Back")
    }
}

struct BrassNavigationHeader: View {
    let title: String
    var subtitle: String?
    let onBack: () -> Void

    init(title: String, subtitle: String? = nil, onBack: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            VStack(spacing: 3) {
                Text(title)
                    .appFont(size: 20, weight: .semibold)
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let subtitle {
                    Text(subtitle)
                        .appFont(size: 9)
                        .tracking(1.6)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 52)

            // Unlike an overlay, this row contributes the back button's full
            // height to the header, so its lower edge cannot be clipped.
            HStack {
                BrassBackButton(action: onBack)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Theatre.ink.opacity(0.96))
    }
}

/// A selection control drawn in the same ink-and-brass language as the rest
/// of the app. It deliberately does not use the platform segmented picker, so
/// its geometry, type and selected state remain ours on every OS release.
struct BrassSegmentedPicker<Value: Hashable, Label: View>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let usesPlainLabels: Bool
    @ViewBuilder let label: (Value) -> Label

    init(
        _ title: String,
        selection: Binding<Value>,
        options: [Value],
        usesPlainLabels: Bool = false,
        @ViewBuilder label: @escaping (Value) -> Label
    ) {
        self.title = title
        _selection = selection
        self.options = options
        self.usesPlainLabels = usesPlainLabels
        self.label = label
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selection = option }
                } label: {
                    label(option)
                        // A control this central is not a caption. It was set
                        // at nine points and allowed to shrink to six, which is
                        // where "VS AI" and "Multiplayer" became a pattern
                        // rather than two words.
                        .appFont(size: 12, weight: selected ? .semibold : .medium)
                        .tracking(usesPlainLabels ? 0 : 0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(selected ? Theatre.brassHot : Theatre.ivoryDim)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 9)
                        .background {
                            if selected {
                                BrassPlateShape(cut: 7)
                                    .fill(Theatre.brassGlow)
                            }
                        }
                        .overlay {
                            if selected {
                                BrassPlateShape(cut: 7)
                                    .strokeBorder(Theatre.brass.opacity(0.72), lineWidth: 0.8)
                            }
                        }
                }
                .buttonStyle(BrassPressStyle())
                .accessibilityLabel(labelText(for: option))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background {
            BrassPlateShape(cut: 9).fill(Theatre.ink2)
        }
        .overlay {
            BrassPlateShape(cut: 9)
                .strokeBorder(Theatre.brassDeep.opacity(0.48), lineWidth: 0.75)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func labelText(for option: Value) -> String {
        String(describing: option)
    }
}

/// A compact picker for choices whose labels are too long to divide into
/// equal segments. The arrows cycle through the finite list without opening a
/// system menu.
struct BrassCyclePicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    init(
        _ title: String,
        selection: Binding<Value>,
        options: [Value],
        label: @escaping (Value) -> String
    ) {
        self.title = title
        _selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .appFont(size: 9)
                .tracking(1.5)
                .foregroundStyle(Theatre.ivoryFaint)

            HStack(spacing: 8) {
                arrow("chevron.backward", offset: -1)
                Text(label(selection))
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                arrow("chevron.forward", offset: 1)
            }
            .padding(4)
            .background {
                BrassPlateShape(cut: 9).fill(Theatre.ink2)
            }
            .overlay {
                BrassPlateShape(cut: 9)
                    .strokeBorder(Theatre.brassDeep.opacity(0.48), lineWidth: 0.75)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(label(selection))
        .accessibilityAdjustableAction { direction in
            move(direction == .increment ? 1 : -1)
        }
    }

    private func arrow(_ symbol: String, offset: Int) -> some View {
        Button { move(offset) } label: {
            BrassIcon(symbol, size: 16)
                .foregroundStyle(Theatre.brass)
                .frame(width: 36, height: 34)
                .background {
                    BrassPlateShape(cut: 7).fill(Theatre.ink4)
                }
                .overlay {
                    BrassPlateShape(cut: 7)
                        .strokeBorder(Theatre.brassDeep.opacity(0.55), lineWidth: 0.7)
                }
        }
        .buttonStyle(BrassPressStyle())
    }

    private func move(_ offset: Int) {
        guard !options.isEmpty else { return }
        let current = options.firstIndex(of: selection) ?? 0
        selection = options[(current + offset + options.count) % options.count]
    }
}

/// A switch in the set's own language: a medallion that slides, with a pawn on
/// it and the light coming on behind it.
///
/// It was a notched plate before — the same cut corners the buttons are drawn
/// with, at forty-five points by twenty-five. At that size the notches are a
/// quarter of the shape and it reads as a rounded rectangle somebody has taken
/// bites out of. Corners cut on a button four times the size are a detail; on
/// something this small they are the whole silhouette.
///
/// So: a capsule for the track, because a switch is a groove something runs
/// along, and the knob is the play button's medallion made small — the same
/// rings, the same brass, a pawn instead of the knight. The pawn is the app's
/// own emblem, and the piece a switch should be: the smallest one on the board.
struct BrassToggle: View {
    let title: String
    var symbol: String?
    @Binding var isOn: Bool

    init(_ title: String, symbol: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.symbol = symbol
        _isOn = isOn
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) { isOn.toggle() }
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .appFont(.subheadline)
                    .foregroundStyle(Theatre.ivory)
                Spacer(minLength: 8)
                if let symbol {
                    BrassIcon(symbol, size: 17)
                        .foregroundStyle(isOn ? Theatre.brass : Theatre.ivoryFaint)
                        .frame(width: 20, height: 25)
                        .contentTransition(.symbolEffect(.replace))
                }
                track
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }

    private var track: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn
                      ? LinearGradient(colors: [Theatre.brassDeep, Theatre.brass],
                                       startPoint: .leading, endPoint: .trailing)
                      : LinearGradient(colors: [Theatre.ink2, Theatre.ink4],
                                       startPoint: .leading, endPoint: .trailing))
                .overlay(
                    Capsule().strokeBorder(
                        isOn ? Theatre.brassHot.opacity(0.9) : Theatre.brassDeep.opacity(0.5),
                        lineWidth: 0.8
                    )
                )
            medallion.padding(2.5)
        }
        .frame(width: 54, height: 29)
        // Lit only when it is on, so the switch reads across a dark screen the
        // way the play button does.
        .shadow(color: isOn ? Theatre.brassGlow : .clear, radius: 7)
    }

    private var medallion: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Theatre.brassDeep.opacity(isOn ? 0.55 : 0.28), Theatre.ink2],
                    center: .center, startRadius: 1, endRadius: 13
                ))
            Circle()
                .strokeBorder(isOn ? Theatre.brassHot.opacity(0.95) : Theatre.brassDeep.opacity(0.7),
                              lineWidth: 1)
            PieceView(piece: Piece(.white, .pawn), size: 18)
                // The artwork stands on the baseline of its own square, which
                // is below the middle of the circle it is being set into.
                .offset(y: -1.5)
                .opacity(isOn ? 1 : 0.42)
        }
        .frame(width: 24, height: 24)
        .shadow(color: Theatre.shadow.opacity(0.45), radius: 2, y: 1)
    }
}

struct BrassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let onEditingChanged: (Bool) -> Void

    @State private var isEditing = false

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _value = value
        self.range = range
        self.step = step
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width)
            let progress = fraction

            ZStack(alignment: .leading) {
                Capsule().fill(Theatre.ink4).frame(height: 6)
                Capsule().fill(Theatre.brass).frame(width: width * progress, height: 6)
                Circle()
                    .fill(Theatre.ivory)
                    .overlay(Circle().strokeBorder(Theatre.brassDeep, lineWidth: 1))
                    .shadow(color: Theatre.brassGlow, radius: 6)
                    .frame(width: 20, height: 20)
                    .offset(x: max(0, min(width - 20, width * progress - 10)))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isEditing {
                            isEditing = true
                            onEditingChanged(true)
                        }
                        setValue(at: gesture.location.x, width: width)
                    }
                    .onEnded { gesture in
                        setValue(at: gesture.location.x, width: width)
                        isEditing = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 28)
        .accessibilityElement()
        .accessibilityLabel("Slider")
        .accessibilityValue("\(Int(fraction * 100)) percent")
        .accessibilityAdjustableAction { direction in
            let increment = step ?? (range.upperBound - range.lowerBound) / 20
            value = clamped(value + (direction == .increment ? increment : -increment))
        }
    }

    private var fraction: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return min(1, max(0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    private func setValue(at x: CGFloat, width: CGFloat) {
        let raw = range.lowerBound + Double(min(1, max(0, x / width))) * (range.upperBound - range.lowerBound)
        let stepped = step.map { (raw / $0).rounded() * $0 } ?? raw
        value = clamped(stepped)
    }

    private func clamped(_ proposed: Double) -> Double {
        min(range.upperBound, max(range.lowerBound, proposed))
    }
}

struct BrassActivityIndicator: View {
    var size: CGFloat = 18
    @State private var rotates = false

    var body: some View {
        Circle()
            .trim(from: 0.08, to: 0.78)
            .stroke(Theatre.brass, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotates ? 360 : 0))
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: rotates)
            .onAppear { rotates = true }
            .onDisappear { rotates = false }
            .accessibilityLabel("Loading")
    }
}

struct BrassProgressBar: View {
    let value: Double
    let total: Double

    var body: some View {
        GeometryReader { geometry in
            let fraction = total > 0 ? min(1, max(0, value / total)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Theatre.ink4)
                Capsule().fill(Theatre.brass).frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: 5)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((total > 0 ? value / total : 0) * 100)) percent")
    }
}

struct BrassSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 7) {
            BrassIcon("magnifyingglass", size: 17)
                .foregroundStyle(Theatre.ivoryFaint)
            TextField(placeholder, text: $text)
                .appFont(.subheadline)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    BrassIcon("xmark.circle.fill", size: 18)
                        .foregroundStyle(Theatre.ivoryFaint)
                        .frame(width: 24, height: 22)
                        .background {
                            BrassPlateShape(cut: 5).fill(Theatre.ink4)
                        }
                }
                .buttonStyle(BrassPressStyle())
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            BrassPlateShape(cut: 9).fill(Theatre.ink3)
        }
        .overlay {
            BrassPlateShape(cut: 9)
                .strokeBorder(Theatre.brassDeep.opacity(0.42), lineWidth: 0.6)
        }
    }
}

struct BrassLinkButton: View {
    @Environment(\.openURL) private var openURL
    let title: String
    let destination: URL

    var body: some View {
        Button { openURL(destination) } label: {
            HStack(spacing: 5) {
                Text(title)
                BrassIcon("arrow.up.right", size: 13)
            }
            .foregroundStyle(Theatre.brass)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background {
                BrassPlateShape(cut: 6).fill(Theatre.ink3)
            }
            .overlay {
                BrassPlateShape(cut: 6)
                    .strokeBorder(Theatre.brassDeep.opacity(0.48), lineWidth: 0.65)
            }
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityHint(destination.absoluteString)
    }
}

struct BrassConfirmationOverlay: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        BrassModalBackdrop(onBackdropTap: onCancel) {
            BrassModalPanel(tint: Theatre.bad) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .appFont(.title2, weight: .semibold)
                        .foregroundStyle(Theatre.ivory)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    if !message.isEmpty {
                        Text(message)
                            .appFont(.subheadline)
                            .foregroundStyle(Theatre.ivoryDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 9) {
                        Button(cancelTitle, action: onCancel)
                            .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                            .frame(maxWidth: .infinity)
                        Button(confirmTitle, action: onConfirm)
                            .buttonStyle(PillButtonStyle(emphasis: .danger, usesBodySize: true))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}
