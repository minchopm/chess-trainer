// The 2D board lives in its own module so the App Clip can draw a position
// without linking an engine. The app used it as if it were part of itself
// long before the split, in twenty-odd files; re-exporting keeps all of them
// as they were rather than adding an import to each.
@_exported import BoardUI
