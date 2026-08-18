import Foundation

extension Array where Element: Identifiable {
    /// A copy with `element` replacing the one that shares its id, or appended when
    /// there is none.
    func upserting(_ element: Element) -> [Element] {
        guard contains(where: { $0.id == element.id }) else { return self + [element] }
        return map { $0.id == element.id ? element : $0 }
    }

    /// A copy without the element carrying `id`.
    func removing(id: Element.ID) -> [Element] {
        filter { $0.id != id }
    }
}
