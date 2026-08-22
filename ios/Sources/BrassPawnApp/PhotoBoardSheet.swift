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
    @State private var taps: [CGPoint] = []
    @State private var isCapturing = false
    @State private var isReading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.t("photo.title", "Read a board from a photo"))
                .appFont(size: 22, weight: .semibold)

            if let image {
                Text(instruction)
                    .appFont(.footnote)
                    .foregroundStyle(taps.count == 4 ? Theatre.brass : Theatre.ivoryDim)

                tappable(image)

                HStack(spacing: 8) {
                    Button(L.t("photo.again", "Start again")) {
                        taps = []
                        self.image = nil
                    }
                    .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))

                    if !taps.isEmpty {
                        Button(L.t("photo.undoTap", "Undo tap")) { taps.removeLast() }
                            .buttonStyle(PillButtonStyle(emphasis: .ghost, usesBodySize: true))
                    }

                    Spacer()

                    Button(L.t("photo.read", "Read it")) { read(image) }
                        .buttonStyle(PillButtonStyle(
                            emphasis: .solid, enabled: taps.count == 4 && !isReading, usesBodySize: true
                        ))
                        .disabled(taps.count != 4 || isReading)
                }
            } else {
                Text(L.t("photo.hint",
                         "Photograph the board, then tap its four corners. Whatever comes out opens in the editor for you to correct — a photograph gets a few squares wrong even at its best."))
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
                image = captured
                taps = []
            }
            .ignoresSafeArea()
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let loaded = UIImage(data: data) {
                    image = loaded
                    taps = []
                }
            }
        }
    }

    private var instruction: String {
        switch taps.count {
        case 0: L.t("photo.tapCorners", "Tap the four corners of the board.")
        case 4: L.t("photo.cornersDone", "Four corners marked.")
        default: L.t("photo.cornersLeft", "%lld more to tap.", 4 - taps.count)
        }
    }

    /// The picture, with the taps drawn on it.
    ///
    /// The taps are recorded in the picture's own pixels rather than in view
    /// points, because that is the space the corners have to be in by the time
    /// they reach the rectifier, and converting later means keeping the view's
    /// size around to convert with.
    private func tappable(_ image: UIImage) -> some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / image.size.width,
                            geometry.size.height / image.size.height)
            let shown = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: shown.width, height: shown.height)

                ForEach(Array(taps.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .strokeBorder(Theatre.brass, lineWidth: 2)
                        .background(Circle().fill(Theatre.brass.opacity(0.25)))
                        .frame(width: 22, height: 22)
                        .position(x: point.x * scale, y: point.y * scale)
                        .overlay {
                            Text("\(index + 1)")
                                .appFont(.caption, weight: .semibold)
                                .foregroundStyle(Theatre.brassHot)
                                .position(x: point.x * scale, y: point.y * scale)
                        }
                }
            }
            .frame(width: shown.width, height: shown.height)
            .contentShape(.rect)
            .onTapGesture { location in
                guard taps.count < 4, scale > 0 else { return }
                taps.append(CGPoint(x: location.x / scale, y: location.y / scale))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxHeight: 420)
    }

    private func read(_ image: UIImage) {
        guard let cgImage = image.cgImage,
              let corners = BoardGeometry.order(taps),
              let rectified = BoardPhoto.rectify(cgImage, corners: corners) else { return }

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
