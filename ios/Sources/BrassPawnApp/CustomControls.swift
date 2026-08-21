import SwiftUI

struct BrassBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theatre.brassHot)
                .frame(width: 40, height: 38)
                .background {
                    BrassPlateShape(cut: 9).fill(LinearGradient(
                        colors: [Theatre.ink4, Theatre.ink2],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                }
                .overlay {
                    BrassPlateShape(cut: 9)
                        .strokeBorder(Theatre.brassDeep.opacity(0.7), lineWidth: 0.8)
                }
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
        VStack(spacing: 3) {
            Text(title)
                .font(Face.display(20))
                .foregroundStyle(Theatre.ivory)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(Face.mono(9))
                    .tracking(1.6)
                    .foregroundStyle(Theatre.ivoryFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 52)
        // Navigation controls are deliberately overlaid. They must never
        // consume width from, or shift, the centred title.
        .overlay(alignment: .leading) {
            BrassBackButton(action: onBack)
        }
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
    @ViewBuilder let label: (Value) -> Label

    init(
        _ title: String,
        selection: Binding<Value>,
        options: [Value],
        @ViewBuilder label: @escaping (Value) -> Label
    ) {
        self.title = title
        _selection = selection
        self.options = options
        self.label = label
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selection = option }
                    SoundBoard.shared.play(.move)
                } label: {
                    label(option)
                        .font(Face.mono(9, weight: selected ? .semibold : .medium))
                        .tracking(0.7)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
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
                .font(Face.mono(9))
                .tracking(1.5)
                .foregroundStyle(Theatre.ivoryFaint)

            HStack(spacing: 8) {
                arrow("chevron.left", offset: -1)
                Text(label(selection))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theatre.ivory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                arrow("chevron.right", offset: 1)
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
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
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
        SoundBoard.shared.play(.move)
    }
}

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
            withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) { isOn.toggle() }
            SoundBoard.shared.play(.move)
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theatre.ivory)
                Spacer(minLength: 8)
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isOn ? Theatre.brass : Theatre.ivoryFaint)
                        .frame(width: 20, height: 25)
                        .contentTransition(.symbolEffect(.replace))
                }
                ZStack(alignment: isOn ? .trailing : .leading) {
                    BrassPlateShape(cut: 6)
                        .fill(isOn ? Theatre.brass : Theatre.ink4)
                        .overlay(
                            BrassPlateShape(cut: 6)
                                .strokeBorder(isOn ? Theatre.brassHot : Theatre.brassDeep.opacity(0.55), lineWidth: 0.75)
                        )
                    Circle()
                        .fill(isOn ? Theatre.ink : Theatre.ivoryDim)
                        .padding(3)
                        .shadow(color: Theatre.shadow.opacity(0.35), radius: 2, y: 1)
                }
                .frame(width: 45, height: 25)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(BrassPressStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
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
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(Theatre.ivoryFaint)
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
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
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
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
        ZStack {
            Theatre.shadow.opacity(0.72)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            Panel {
                Text(title)
                    .font(Face.display(25))
                    .foregroundStyle(Theatre.ivory)
                if !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Theatre.ivoryDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 9) {
                    Button(cancelTitle, action: onCancel)
                        .buttonStyle(PillButtonStyle(emphasis: .ghost))
                    Button(confirmTitle, action: onConfirm)
                        .buttonStyle(PillButtonStyle(emphasis: .danger))
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: 390)
            .padding(24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .accessibilityAddTraits(.isModal)
    }
}
