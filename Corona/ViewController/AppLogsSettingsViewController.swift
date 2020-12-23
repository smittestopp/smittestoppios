import UIKit

class AppLogsSettingsViewController: UITableViewController {
    typealias Dependencies =
        HasLocalStorageService
    var dependencies: Dependencies?

    @IBOutlet weak var clearFileCell: UITableViewCell!
    @IBOutlet weak var filenameCell: UITableViewCell!
    @IBOutlet weak var toggleLogfileSwitch: UISwitch!

    @IBOutlet weak var clearGPSFileCell: UITableViewCell!
    @IBOutlet weak var toggleGPSLogfileSwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Logfile.shared.loggingEnabled = dependencies!.localStorage.logToFile
        populateData()
    }

    @IBAction func logToFileValueChanged(_ sender: Any) {
        guard let toggler = sender as? UISwitch else {
            return
        }
        dependencies!.localStorage.logToFile = toggler.isOn
        Logfile.shared.loggingEnabled = toggler.isOn
    }

    @IBAction func logToGPSFilesValueChange(_ sender: Any) {
        guard let toggler = sender as? UISwitch else {
            return
        }
        CSVFileApi.shared.enabled = toggler.isOn
    }

    func isLoggingToFile() -> Bool {
        return Logfile.shared.loggingEnabled
    }

    func isLoggingToGPSFiles() -> Bool {
        return CSVFileApi.shared.enabled
    }

    func clearLogFile() {
        Logfile.shared.clearLogFile()
    }

    func clearGPSLogFiles() {
        CSVFileApi.shared.clearLogFiles()
    }

    private func populateData() {
        filenameCell.detailTextLabel?.text = Logfile.shared.filePath?.lastPathComponent ?? "File not found."
        toggleLogfileSwitch.setOn(isLoggingToFile(), animated: true)
        toggleGPSLogfileSwitch.setOn(isLoggingToGPSFiles(), animated: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case clearFileCell:
            tableView.deselectRow(at: indexPath, animated: true)
            clearLogFile()

        case clearGPSFileCell:
            tableView.deselectRow(at: indexPath, animated: true)
            clearGPSLogFiles()

        default:
            return
        }
    }
}
