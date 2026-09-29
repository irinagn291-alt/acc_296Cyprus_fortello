import Foundation

/// Role: Work. One saved canvas in the crate. Called-ness is the file case, not a parallel bool.
enum WorkFile: String, Codable, Sendable, Equatable {
    case loose
    case called
}

/// Role: Work. Object id is the duplicate key. Quiz draws only from Loose rows.
struct Work: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var objectID: Int
    var accession: String
    var artist: String
    var title: String
    var imageHref: String?
    var objectHref: String?
    var isPublicDomain: Bool
    var daykey: Int
    var file: WorkFile

    var imageURL: URL? {
        guard let imageHref, let url = URL(string: imageHref), !imageHref.isEmpty else {
            return nil
        }
        return url
    }

    static func loose(
        from row: CatalogRow,
        id: UUID = UUID(),
        daykey: Int
    ) -> Work {
        Work(
            id: id,
            objectID: row.objectID,
            accession: row.accession,
            artist: row.artist,
            title: row.title,
            imageHref: row.imageHref,
            objectHref: row.objectHref,
            isPublicDomain: row.isPublicDomain,
            daykey: daykey,
            file: .loose
        )
    }
}

/// Role: Work. Catalog row before it is filed Loose. Cached so empty or failed Met search still hangs.
struct CatalogRow: Identifiable, Equatable, Sendable, Codable {
    var objectID: Int
    var accession: String
    var artist: String
    var title: String
    var imageHref: String?
    var objectHref: String?
    var isPublicDomain: Bool

    var id: Int { objectID }

    var imageURL: URL? {
        guard let imageHref, let url = URL(string: imageHref), !imageHref.isEmpty else {
            return nil
        }
        return url
    }
}
