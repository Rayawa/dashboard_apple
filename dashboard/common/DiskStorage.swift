import Foundation

final class DiskStorage {
    private let namespace: String

    init(namespace: String) {
        self.namespace = namespace
    }

    func get<T>(_ key: String, defaultValue: T) -> T {
        UserDefaults.standard.object(forKey: namespaced(key)) as? T ?? defaultValue
    }

    func set<T>(_ key: String, value: T) {
        UserDefaults.standard.set(value, forKey: namespaced(key))
    }

    private func namespaced(_ key: String) -> String {
        "\(namespace).\(key)"
    }
}
