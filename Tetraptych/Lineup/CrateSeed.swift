import Foundation

/// Role: Lineup. Simulator demo crate. Device never writes this. Key: tpt.demo.v1.
enum CrateSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func crate(
        now: Date = Date(),
        calendar: Calendar = .current,
        caster: any LineupCasting = LeadingTrueCast(kind: .artist),
        shelf: [CatalogRow] = CrateShelf.bundled.rows
    ) -> Pinacotheca {
        let today = Daykey.stamp(now, calendar: calendar)
        let rows = shelf
        func work(_ row: CatalogRow, id: UUID, file: WorkFile, dayOffset: Int) -> Work {
            var item = Work.loose(
                from: row,
                id: id,
                daykey: Daykey.shifting(today, by: dayOffset, calendar: calendar)
            )
            item.file = file
            return item
        }

        let gogh = work(rows[0], id: fixed("AAAAAAAA-0001-4000-8000-000000000001"), file: .loose, dayOffset: 0)
        let vermeer = work(rows[1], id: fixed("AAAAAAAA-0001-4000-8000-000000000002"), file: .loose, dayOffset: -1)
        let homer = work(rows[2], id: fixed("AAAAAAAA-0001-4000-8000-000000000003"), file: .loose, dayOffset: -2)
        let sargent = work(rows[3], id: fixed("AAAAAAAA-0001-4000-8000-000000000004"), file: .loose, dayOffset: -3)
        let seurat = work(rows[4], id: fixed("AAAAAAAA-0001-4000-8000-000000000005"), file: .loose, dayOffset: -4)
        let david = work(rows[5], id: fixed("AAAAAAAA-0001-4000-8000-000000000006"), file: .loose, dayOffset: -5)
        let moreau = work(rows[6], id: fixed("AAAAAAAA-0001-4000-8000-000000000007"), file: .called, dayOffset: -6)
        let manet = work(rows[7], id: fixed("AAAAAAAA-0001-4000-8000-000000000008"), file: .called, dayOffset: -7)

        let works = [gogh, vermeer, homer, sargent, seurat, david, moreau, manet]
        let moreauCard = FaceBench.card(
            trueWork: moreau,
            loose: [moreau, gogh, vermeer, homer],
            caster: caster,
            faceIDs: [
                fixed("EEEEEEEE-0001-4000-8000-000000000011"),
                fixed("EEEEEEEE-0001-4000-8000-000000000012"),
                fixed("EEEEEEEE-0001-4000-8000-000000000013"),
                fixed("EEEEEEEE-0001-4000-8000-000000000014"),
            ]
        )
        let manetCard = FaceBench.card(
            trueWork: manet,
            loose: [manet, sargent, seurat, david],
            caster: caster,
            faceIDs: [
                fixed("EEEEEEEE-0001-4000-8000-000000000021"),
                fixed("EEEEEEEE-0001-4000-8000-000000000022"),
                fixed("EEEEEEEE-0001-4000-8000-000000000023"),
                fixed("EEEEEEEE-0001-4000-8000-000000000024"),
            ]
        )
        let callMarks = [
            CallMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000001"),
                workID: moreau.id,
                card: moreauCard,
                daykey: moreau.daykey
            ),
            CallMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000002"),
                workID: manet.id,
                card: manetCard,
                daykey: manet.daykey
            ),
        ]
        let faultMarks = [
            FaultMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000001"),
                workID: moreau.id,
                faceID: moreauCard.faces.first { !$0.isTrue }?.id ?? fixed("FFFFFFFF-0001-4000-8000-000000000001"),
                daykey: moreau.daykey,
                cue: moreauCard.cue
            ),
            FaultMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000002"),
                workID: manet.id,
                faceID: manetCard.faces.first { !$0.isTrue }?.id ?? fixed("FFFFFFFF-0001-4000-8000-000000000002"),
                daykey: manet.daykey,
                cue: manetCard.cue
            ),
            FaultMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000003"),
                workID: moreau.id,
                faceID: moreauCard.faces.last { !$0.isTrue }?.id ?? fixed("FFFFFFFF-0001-4000-8000-000000000003"),
                daykey: moreau.daykey,
                cue: moreauCard.cue
            ),
        ]
        var crate = Pinacotheca(
            schemaVersion: Pinacotheca.currentSchema,
            onboardingComplete: true,
            works: works,
            lineup: .idle,
            callMarks: callMarks,
            faultMarks: faultMarks,
            peelLog: [
                PeelRef(kind: .call, markID: callMarks[0].id),
                PeelRef(kind: .fault, markID: faultMarks[0].id),
                PeelRef(kind: .call, markID: callMarks[1].id),
                PeelRef(kind: .fault, markID: faultMarks[1].id),
                PeelRef(kind: .fault, markID: faultMarks[2].id),
            ],
            cachedRows: Array(rows.prefix(6)),
            focusedWorkID: gogh.id
        )
        try? crate.dealCue(
            now: now,
            calendar: calendar,
            caster: caster,
            faceIDs: [
                fixed("EEEEEEEE-0001-4000-8000-000000000001"),
                fixed("EEEEEEEE-0001-4000-8000-000000000002"),
                fixed("EEEEEEEE-0001-4000-8000-000000000003"),
                fixed("EEEEEEEE-0001-4000-8000-000000000004"),
            ]
        )
        return crate
    }
}
