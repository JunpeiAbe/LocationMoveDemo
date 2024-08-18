import Foundation

class LogManager {
    static let shared = LogManager()
    private var fileName: String?
    private init() {
        
    }
    
    /// ログを書き込む
    func writeLog(_ log: String) {
        // ファイル名がまだ設定されていない場合、一度だけ設定
        if fileName == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            fileName = "GeofenceLog_\(timestamp).txt"
        }
        
        // ファイル名が決まっていることを確認
        guard let fileName = fileName else { return }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        // 追記モードでログを書き込む
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                if let data = (log + "\n").data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            // ファイルが存在しない場合、新しく作成
            try? log.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    /// ファイルのURLを取得
    func getLogFileURL() -> URL? {
        guard let fileName = fileName else { return nil }
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        return fileURL
    }
}
