extension Locale {
    var normalizedIdentifier: String {
        // ex. en_JP@calendar=japanese
        let identifierWithoutCalendar = identifier.components(separatedBy: "@").first ?? identifier
        return identifierWithoutCalendar.replacingOccurrences(of: "_", with: "-").lowercased()
    }
}
