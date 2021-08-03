extension CGSize {
    /// returns a `CGSize` with the smallest integer values for its size to prevent drawing on pixel boundaries
    var integral: CGSize {
        CGSize(width: ceil(width), height: ceil(height))
    }
}
