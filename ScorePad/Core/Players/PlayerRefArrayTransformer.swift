import Foundation

// Stores [PlayerRef] as an NSKeyedArchiver binary plist so the format matches the
// legacy NSKeyedUnarchiveFromData transformer that CoreData used for [String] attributes.
// This lets CloudKit-synced records written in the old bare-string format be decoded
// gracefully instead of crashing when SwiftData tries to JSON-parse them.
//
// Forward:  [PlayerRef] → NSData  (array of dicts: {"name", "profileID"?})
// Reverse:  NSData → [PlayerRef], handles:
//   • Legacy bare-string elements (old team1Players: [String] format)
//   • Current dict elements written by this transformer
@objc(PlayerRefArrayTransformer)
final class PlayerRefArrayTransformer: ValueTransformer {

    static let transformerName = "PlayerRefArrayTransformer"

    static func register() {
        ValueTransformer.setValueTransformer(
            PlayerRefArrayTransformer(),
            forName: NSValueTransformerName(transformerName))
    }

    override class func transformedValueClass() -> AnyClass { NSData.self }
    override class func allowsReverseTransformation() -> Bool { true }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let refs = value as? [PlayerRef] else { return nil }
        let array = refs.map { ref -> NSDictionary in
            var d: [String: Any] = ["name": ref.name]
            if let id = ref.profileID { d["profileID"] = id.uuidString }
            return d as NSDictionary
        } as NSArray
        return try? NSKeyedArchiver.archivedData(withRootObject: array,
                                                  requiringSecureCoding: false) as NSData
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return [PlayerRef]() }

        // Try secure path first (data written by this transformer)
        var array: NSArray? = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [NSArray.self, NSString.self, NSDictionary.self],
            from: data) as? NSArray

        // Fall back to non-secure path for legacy [String] data written by CoreData's
        // NSKeyedUnarchiveFromData transformer (the one SwiftData uses by default for arrays)
        if array == nil {
            array = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSArray
        }

        guard let array else { return [PlayerRef]() }

        return array.compactMap { element -> PlayerRef? in
            if let name = element as? String {
                // Legacy format: plain string element
                return PlayerRef(name: name)
            } else if let dict = element as? [String: Any], let name = dict["name"] as? String {
                // Current format: dict element
                var ref = PlayerRef(name: name)
                ref.profileID = (dict["profileID"] as? String).flatMap(UUID.init(uuidString:))
                return ref
            }
            return nil
        }
    }
}
