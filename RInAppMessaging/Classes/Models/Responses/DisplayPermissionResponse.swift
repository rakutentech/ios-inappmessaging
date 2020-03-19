/// Data model for displaying campaign permission.
internal struct DisplayPermissionResponse: Decodable {
    let display: Bool
    let performPing: Bool
}
