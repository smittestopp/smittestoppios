import Foundation

enum StorableEvent {
    /// GPS event
    case gps(StorableGPSEvent)
    case stats(StorableStatistic)
    case bluetooth(StorableBLEEvent)
}
