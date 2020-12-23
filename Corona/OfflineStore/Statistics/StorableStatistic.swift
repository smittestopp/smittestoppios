import Foundation

enum StorableStatistic {
    case uploadStarted(UploadStatisticsData)
    case uploadSucceeded(UploadStatisticsData)
    case uploadFailed(UploadStatisticsData, reason: String)
}
