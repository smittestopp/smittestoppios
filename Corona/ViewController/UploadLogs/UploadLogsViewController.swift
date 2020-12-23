import UIKit

class UploadLogsViewController: UITableViewController {
    typealias Dependencies =
        HasOfflineStore
    var dependencies: Dependencies?

    struct Item {
        let date: String
        let message: String
    }

    var logs: [Item] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func loadData() {
        let df = DateFormatter()
        df.dateFormat = "MMM dd HH:mm:ss"

        let dcf = DateComponentsFormatter()
        dcf.unitsStyle = .abbreviated

        logs = dependencies!.offlineStore.getUploadLogs()
            .map { entry -> Item in
                let date = df.string(from: entry.date)
                let message: String = {
                    let messageOrEmpty = entry.message.map { ": \($0)" } ?? ""
                    switch entry.type {
                    case .started:
                        return "Started with \(entry.numberOfEvents) \(entry.dataType) events"

                    case .succeeded:
                        let duration = entry.date.timeIntervalSince(entry.startDate)
                        let durationString = dcf.string(from: duration) ?? "nil"

                        return "Uploaded \(entry.numberOfEvents) \(entry.dataType) events in \(durationString)"

                    case .failed:
                        let duration = entry.date.timeIntervalSince(entry.startDate)
                        let durationString = dcf.string(from: duration) ?? "nil"

                        return "Failed \(entry.numberOfEvents) \(entry.dataType) events after \(durationString)\(messageOrEmpty)"
                    }
                }()
                return Item(date: date, message: message)
            }

        tableView.reloadData()
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return logs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: UploadLogsCell.reuseIdentifier, for: indexPath) as! UploadLogsCell
        let item = logs[indexPath.row]
        cell.dateLabel.text = item.date
        cell.messageLabel.text = item.message
        return cell
    }
}
