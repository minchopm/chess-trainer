import ChessCore
import ChessTraining
import PhotosUI
import SwiftUI

#if canImport(UIKit)
import UIKit

/// The camera, for a board that is in front of you rather than in your library.
///
/// `PhotosPicker` reaches the library and nothing else, and the ordinary case
/// for this feature is a board on a table and a phone in your hand.
private struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// The picker's label, as a type rather than an expression.
///
/// `PhotosPicker` takes its label in a sendable closure, which cannot reach
/// main-actor state — and the app's typography is main-actor state. A `View`
/// with no stored properties can be constructed from anywhere, and its body
/// runs where bodies run.
private struct ChooseLabel: View {
    var body: some View {
        Text(L.t("photo.choose", "Choose a photo"))
            .appFont(.body, weight: .semibold)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background { BrassPlateShape(cut: 10).fill(Theatre.brass.opacity(0.12)) }
            .overlay { BrassPlateShape(cut: 10).strokeBorder(Theatre.brass.opacity(0.5), lineWidth: 0.8) }
            .foregroundStyle(Theatre.brass)
    }
}

/// Read a position off a photograph.
///
/// The corners are tapped rather than found. Every published pipeline finds the
/// board by looking for lines, and that is the step that breaks on real
/// photographs — the best-measured one locates the board in about a third of
/// phone pictures, and everything downstream inherits the miss. Four taps take
/// that failure to nothing and cost a moment.
///
/// Whatever comes out goes to the editor, always. Even the best published
/// reader gets three or four squares wrong on an average board, so the
/// correction step is the feature rather than a safety net.
struct PhotoBoardSheet: View {
    @Binding var isPresented: Bool
    let reader: any SquareReader
    let use: ([Square: Piece]) -> Void

    @State private var picked: PhotosPickerItem?
    @State private var image: UIImage?
    /// The four corners, in the picture's own pixels. Always four of them.
    @State private var corners: [CGPoint] = []
    /// Which corner is under the finger, so the loupe knows what to show.
    @State private var dragging: Int?
    @State private var isCapturing = false
    @State private var isReading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.t("photo.title", "Read a board from a photo"))
                .appFont(size: 22, weight: .semibold)

            if let image {
                Text(L.t("photo.dragCorners",
                         "Drag the four handles onto the corners of the board."))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)

                adjustable(image)

                HStack(spacing: 8) {
                    Button(L.t("photo.again", "Start again")) {
                        corners = []
                        self.image = nil
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))

                    Spacer()

                    Button(L.t("photo.read", "Read it")) { read(image) }
                        .buttonStyle(PillButtonStyle(
                            emphasis: .solid, enabled: !isReading, usesBodySize: true
                        ))
                        .disabled(isReading)
                }
            } else {
                Text(L.t("photo.hint",
                         "Photograph the whole board with its edges in frame. Whatever comes out opens in the editor for you to correct — a photograph gets a few squares wrong even at its best."))
                    .appFont(.footnote)
                    .foregroundStyle(Theatre.ivoryDim)

                Spacer()

                HStack(spacing: 8) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(L.t("photo.camera", "Take a photo")) { isCapturing = true }
                            .buttonStyle(PillButtonStyle(emphasis: .solid, usesBodySize: true))
                    }
                    PhotosPicker(selection: $picked, matching: .images) { ChooseLabel() }
                }

                Spacer()
            }

            Button(L.t("common.cancel", "Cancel")) { isPresented = false }
                .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theatre.ink2)
        .fullScreenCover(isPresented: $isCapturing) {
            CameraPicker { captured in
                corners = []
                image = captured
            }
            .ignoresSafeArea()
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let loaded = UIImage(data: data) {
                    corners = []
                    image = loaded
                }
            }
        }
    }

    /// The picture with four draggable handles on it.
    ///
    /// Handles rather than taps. Tapping asks somebody to hit a point their own
    /// fingertip is covering, in a picture shrunk to fit the screen — and if the
    /// board runs to the edge of the frame, the corner cannot be hit at all.
    /// Four handles are placed for you and dragged into place, which is how
    /// every document scanner does it and for the same reasons.
    private func adjustable(_ image: UIImage) -> some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / image.size.width,
                            geometry.size.height / image.size.height)
            let shown = CGSize(width: image.size.width * scale,
                               height: image.size.height * scale)

            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: shown.width, height: shown.height)

                quadOutline(scale: scale)

                ForEach(corners.indices, id: \.self) { index in
                    handle(index: index, scale: scale, image: image)
                }

                if let dragging, corners.indices.contains(dragging) {
                    loupe(image: image, at: corners[dragging], shown: shown, scale: scale)
                }
            }
            .frame(width: shown.width, height: shown.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear { placeCornersIfNeeded(in: image) }
            .onChange(of: image) { _, new in
                corners = []
                placeCornersIfNeeded(in: new)
            }
        }
    }

    /// The quadrilateral being adjusted, so its shape can be judged as a whole
    /// rather than one corner at a time.
    private func quadOutline(scale: CGFloat) -> some View {
        Path { path in
            guard corners.count == 4 else { return }
            let points = corners.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
            path.addLines(points)
            path.closeSubpath()
        }
        .stroke(Theatre.brass.opacity(0.9), lineWidth: 1.5)
    }

    private func handle(index: Int, scale: CGFloat, image: UIImage) -> some View {
        let point = corners[index]
        return Circle()
            .strokeBorder(Theatre.brass, lineWidth: 2)
            .background(Circle().fill(Theatre.brass.opacity(dragging == index ? 0.45 : 0.2)))
            .frame(width: 30, height: 30)
            // The touch target is larger than the ring, because a fingertip is
            // larger than a ring.
            .contentShape(Circle().inset(by: -14))
            .position(x: point.x * scale, y: point.y * scale)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragging = index
                        corners[index] = clamp(
                            CGPoint(x: value.location.x / scale, y: value.location.y / scale),
                            to: image.size
                        )
                    }
                    .onEnded { _ in dragging = nil }
            )
    }

    /// What is under the finger, shown where the finger is not.
    ///
    /// Parked in the corner furthest from the handle being dragged: a loupe that
    /// follows the finger is covered by the same hand it is meant to help.
    private func loupe(image: UIImage, at point: CGPoint, shown: CGSize, scale: CGFloat) -> some View {
        let size: CGFloat = 108
        let magnification: CGFloat = 2.6
        let onTheLeft = point.x * scale > shown.width / 2
        let onTop = point.y * scale > shown.height / 2

        return ZStack {
            Image(uiImage: image)
                .resizable()
                .frame(width: image.size.width * scale * magnification,
                       height: image.size.height * scale * magnification)
                .offset(x: size / 2 - point.x * scale * magnification,
                        y: size / 2 - point.y * scale * magnification)
            Path { path in
                path.move(to: CGPoint(x: size / 2, y: 0))
                path.addLine(to: CGPoint(x: size / 2, y: size))
                path.move(to: CGPoint(x: 0, y: size / 2))
                path.addLine(to: CGPoint(x: size, y: size / 2))
            }
            .stroke(Theatre.brass.opacity(0.85), lineWidth: 1)
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay { Circle().strokeBorder(Theatre.brass, lineWidth: 1.5) }
        .position(
            x: onTheLeft ? size / 2 + 8 : shown.width - size / 2 - 8,
            y: onTop ? size / 2 + 8 : shown.height - size / 2 - 8
        )
        .allowsHitTesting(false)
    }

    /// Four handles, set in from the picture's own corners.
    ///
    /// Inside rather than exactly on them, because a board photographed with any
    /// margin has its corners inside the frame — and a handle sitting on the
    /// very edge looks like part of the frame rather than something to move.
    private func placeCornersIfNeeded(in image: UIImage) {
        guard corners.isEmpty else { return }
        let inset = CGPoint(x: image.size.width * 0.12, y: image.size.height * 0.12)
        corners = [
            CGPoint(x: inset.x, y: inset.y),
            CGPoint(x: image.size.width - inset.x, y: inset.y),
            CGPoint(x: image.size.width - inset.x, y: image.size.height - inset.y),
            CGPoint(x: inset.x, y: image.size.height - inset.y),
        ]
    }

    /// A handle may go right to the edge — a board can run off the frame — but
    /// not past it, where there is no photograph to read.
    private func clamp(_ point: CGPoint, to size: CGSize) -> CGPoint {
        CGPoint(x: min(max(0, point.x), size.width), y: min(max(0, point.y), size.height))
    }

    private func read(_ image: UIImage) {
        guard let cgImage = image.cgImage,
              let ordered = BoardGeometry.order(corners),
              let rectified = BoardPhoto.rectify(cgImage, corners: ordered) else { return }

        isReading = true
        Task {
            let found = await reader.read(BoardPhoto.crops(from: rectified))
            isReading = false
            use(found)
            isPresented = false
        }
    }

}
#endif
