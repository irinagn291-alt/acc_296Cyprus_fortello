import Foundation

/// Role: Work. Bundled crate shelf. Empty or failed Met search hangs from here. Not a food catalog.
struct CrateShelf: Sendable {
    var rows: [CatalogRow]

    static let bundled = CrateShelf(rows: Self.makeRows())

    private static func makeRows() -> [CatalogRow] {
        [
            row(
                436535,
                "1993.132",
                "Vincent van Gogh",
                "Wheat Field with Cypresses",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP-42549-001.jpg",
                "https://www.metmuseum.org/art/collection/search/436535"
            ),
            row(
                437881,
                "89.15.21",
                "Johannes Vermeer",
                "Young Woman with a Water Pitcher",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP353257.jpg",
                "https://www.metmuseum.org/art/collection/search/437881"
            ),
            row(
                11122,
                "06.1234",
                "Winslow Homer",
                "The Gulf Stream",
                "https://images.metmuseum.org/CRDImages/ad/web-large/DP-20821-001.jpg",
                "https://www.metmuseum.org/art/collection/search/11122"
            ),
            row(
                12127,
                "16.53",
                "John Singer Sargent",
                "Madame X (Virginie Amélie Avegno Gautreau)",
                "https://images.metmuseum.org/CRDImages/ad/web-large/DP-29006-001.jpg",
                "https://www.metmuseum.org/art/collection/search/12127"
            ),
            row(
                437654,
                "61.101.17",
                "Georges Seurat",
                "Circus Sideshow (Parade de cirque)",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP375450_cropped.jpg",
                "https://www.metmuseum.org/art/collection/search/437654"
            ),
            row(
                436105,
                "31.45",
                "Jacques Louis David",
                "The Death of Socrates",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP-13139-001.jpg",
                "https://www.metmuseum.org/art/collection/search/436105"
            ),
            row(
                437153,
                "21.134.1",
                "Gustave Moreau",
                "Oedipus and the Sphinx",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP-14201-023.jpg",
                "https://www.metmuseum.org/art/collection/search/437153"
            ),
            row(
                436947,
                "29.100.115",
                "Edouard Manet",
                "Boating",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP-25466-001.jpg",
                "https://www.metmuseum.org/art/collection/search/436947"
            ),
            row(
                437394,
                "61.198",
                "Rembrandt (Rembrandt van Rijn)",
                "Aristotle with a Bust of Homer",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP-30758-001.jpg",
                "https://www.metmuseum.org/art/collection/search/437394"
            ),
            row(
                437853,
                "99.31",
                "Joseph Mallord William Turner",
                "Venice, from the Porch of Madonna della Salute",
                "https://images.metmuseum.org/CRDImages/ep/web-large/DP169568.jpg",
                "https://www.metmuseum.org/art/collection/search/437853"
            ),
        ]
    }

    private static func row(
        _ objectID: Int,
        _ accession: String,
        _ artist: String,
        _ title: String,
        _ imageHref: String,
        _ objectHref: String
    ) -> CatalogRow {
        CatalogRow(
            objectID: objectID,
            accession: accession,
            artist: artist,
            title: title,
            imageHref: imageHref,
            objectHref: objectHref,
            isPublicDomain: true
        )
    }
}
