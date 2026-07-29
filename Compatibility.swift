import SwiftUI

// MARK: - Glass Effect Compatibility

// Liquid Glass ships in SDK 26 (Swift 6.2), but every symbol is
// `@available(visionOS, unavailable)` — so visionOS still needs these fallbacks.
// The previous `!canImport(GlassKit)` test was always true (there is no such
// framework), which shadowed the real API on iOS and macOS too.
#if !compiler(>=6.2) || os(visionOS)

/// Fallback GlassEffectContainer for older SDKs
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

/// Fallback Glass type for older SDKs
struct Glass {
    var tintColor: Color?
    var isInteractive: Bool = false
    
    static let regular = Glass()
    
    // Mirrors SwiftUI's Glass.tint(_:) / .interactive(_:) so call sites are
    // identical whether this fallback or the real API is in scope.
    func tint(_ color: Color?) -> Glass {
        var copy = self
        copy.tintColor = color
        return copy
    }

    func interactive(_ isEnabled: Bool = true) -> Glass {
        var copy = self
        copy.isInteractive = isEnabled
        return copy
    }
}

extension View {
    /// Fallback glassEffect modifier for older SDKs
    func glassEffect(_ glass: Glass, in shape: some InsettableShape) -> some View {
        self.background(
            shape
                .fill(.ultraThinMaterial)
                .overlay(
                    shape
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}

extension ButtonStyle where Self == GlassProminentButtonStyle {
    static var glassProminent: GlassProminentButtonStyle { GlassProminentButtonStyle() }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GlassProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.blue.opacity(0.15), in: .rect(cornerRadius: 14))
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#endif

// MARK: - Reorderable Compatibility

// SwiftUI's reorderable containers ship in the SDK 27 / Swift 6.4 toolchain
// (Xcode 27), not 6.2 — gating on 6.2 stripped these fallbacks on Xcode 26,
// where SwiftUI has no ReorderDifference of its own.
#if !compiler(>=6.4) || os(watchOS) || os(tvOS)

/// Fallback identifier for reorderable containers
struct ReorderableSingleCollectionIdentifier: Hashable {
    static let `default` = ReorderableSingleCollectionIdentifier()
}

/// Fallback destination for reorder operations
struct ReorderDestination<ItemID: Hashable> {
    enum Position {
        case before(ItemID)
        case end
    }
    
    let collectionID: ReorderableSingleCollectionIdentifier
    let position: Position
}

/// Fallback difference type for reorder operations
struct ReorderDifference<ItemID: Hashable, CollectionID: Hashable> {
    let sources: [ItemID]
    let destination: ReorderDestination<ItemID>
}

extension View {
    /// Fallback reorderable modifier using onDrag/onDrop for older SDKs
    func reorderable() -> some View {
        self
    }
    
    /// Fallback reorderContainer modifier for older SDKs
    func reorderContainer<Item: Identifiable>(
        for itemType: Item.Type,
        onReorder: @escaping (ReorderDifference<Item.ID, ReorderableSingleCollectionIdentifier>) -> Void
    ) -> some View {
        self
    }
}

#endif

// Applies to SwiftUI's ReorderDifference on SDK 27 and to the fallback above on
// older SDKs, so ContentView calls the same `apply(to:)` either way.
#if compiler(>=6.4)
@available(anyAppleOS 27.0, *)
#endif
extension ReorderDifference where CollectionID == ReorderableSingleCollectionIdentifier {
    func apply<C>(to collection: inout C)
        where C: RangeReplaceableCollection,
              C.Element: Identifiable,
              C.Element.ID == ItemID
    {
        let moving = Set(sources)
        guard !moving.isEmpty else { return }

        var moved: [C.Element] = []
        moved.reserveCapacity(moving.count)
        collection.removeAll { element in
            guard moving.contains(element.id) else { return false }
            moved.append(element)
            return true
        }

        switch destination.position {
        case .before(let id):
            let index = collection.firstIndex { $0.id == id } ?? collection.endIndex
            collection.insert(contentsOf: moved, at: index)
        case .end:
            collection.append(contentsOf: moved)
        }
    }
}

// MARK: - MeshGradient Compatibility

// MeshGradient is iOS 18 / macOS 15 / visionOS 2 and up — i.e. SDK 18 (Swift 6.0),
// on every platform. The old `!os(iOS)` test shadowed the real type on macOS and
// visionOS, silently downgrading the backdrop to a linear gradient there.
#if !compiler(>=6.0)

/// Fallback MeshGradient for older SDKs
struct MeshGradient: ShapeStyle {
    let width: Int
    let height: Int
    let points: [[Float]]
    let colors: [Color]
    
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        // Fallback to a linear gradient approximation
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#endif
