import UIKit

class UploadStatsViewController: UITableViewController {
    typealias Dependencies =
        HasOfflineStore & HasUploader & HasLocalStorageService
    var dependencies: Dependencies?

    @IBOutlet weak var numberOfPendingGPSEventsCell: UITableViewCell!
    @IBOutlet weak var numberOfPendingBLEEventsCell: UITableViewCell!
    @IBOutlet weak var uploadNowCell: UITableViewCell!
    @IBOutlet weak var lastUploadAttemptCell: UITableViewCell!
    @IBOutlet weak var lastSuccessfullUploadCell: UITableViewCell!
    @IBOutlet weak var viewLogsCell: UITableViewCell!
    @IBOutlet weak var databaseSizeCell: UITableViewCell!
    @IBOutlet weak var appLogsSettingsCell: UITableViewCell!
    @IBOutlet weak var deviceIdentifierCell: SettingsDeviceIdentifierCell!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)

        reloadData()
    }

    private func reloadData() {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .medium

        let byteFormatter = ByteCountFormatter()
        byteFormatter.countStyle = .file

        let stats = dependencies!.offlineStore.getUploadStats()

        numberOfPendingGPSEventsCell.detailTextLabel?
            .text = "\(stats?.totalNumberOfGPSEvents ?? 0) (\(stats?.numberOfUploadingGPSEvents ?? 0) uploading)"
        numberOfPendingBLEEventsCell.detailTextLabel?
            .text = "\(stats?.totalNumberOfBLEEvents ?? 0) (\(stats?.numberOfUploadingBLEEvents ?? 0) uploading)"
        lastUploadAttemptCell.detailTextLabel?.text = {
            guard let date = stats?.lastAttempt else {
                return "never"
            }
            return df.string(from: date)
        }()
        lastSuccessfullUploadCell.detailTextLabel?.text = {
            guard let date = stats?.lastSuccessfull else {
                return "never"
            }
            return df.string(from: date)
        }()
        databaseSizeCell.detailTextLabel?.text = byteFormatter.string(for: dependencies!.offlineStore.databaseSizeInBytes)

        deviceIdentifierCell.label.text = dependencies?.localStorage.user?.deviceId ?? "none"
    }

    @IBAction func refresh(_: Any) {
        reloadData()
        refreshControl?.endRefreshing()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case numberOfPendingGPSEventsCell,
             numberOfPendingBLEEventsCell,
             lastUploadAttemptCell,
             lastSuccessfullUploadCell,
             databaseSizeCell,
             viewLogsCell,
             appLogsSettingsCell:
            return

        case uploadNowCell:
            tableView.deselectRow(at: indexPath, animated: true)
            DispatchQueue.main.async { [weak self] in
                self?.dependencies?.uploader.upload(.gps)
                self?.dependencies?.uploader.upload(.bluetooth)
                self?.reloadData()
            }

        default:
            break
        }
    }
}
