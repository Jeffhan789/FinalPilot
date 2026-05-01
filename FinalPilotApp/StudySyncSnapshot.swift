import SwiftUI

struct StudySyncSnapshot: Decodable {
    let schemaVersion: Int
    let generatedAt: String
    let localServiceUrl: String
    let syncMode: String
    let selectionPolicy: String
    let sources: [StudySyncSource]
    let metrics: StudySyncMetrics
    let suggestedToday: [StudySyncTask]
    let selectedFiles: [StudySyncFile]
}

struct StudySyncSource: Decodable, Identifiable {
    let id: String
    let courseCode: String
    let title: String
    let rootPath: String
    let exists: Bool
    let filesScanned: Int
    let selectedFiles: Int
    let latestModifiedAt: String?
}

struct StudySyncMetrics: Decodable {
    let selectedFiles: Int
    let totalTasks: Int
    let doneTasks: Int
    let openTasks: Int
    let completionRate: Double
}

struct StudySyncTask: Decodable, Identifiable {
    let id: String
    let courseCode: String
    let title: String
    let done: Bool
    let sourceTitle: String
    let sourcePath: String
    let line: Int
}

struct StudySyncFile: Decodable, Identifiable {
    let id: String
    let sourceId: String
    let courseCode: String
    let title: String
    let relativePath: String
    let absolutePath: String
    let `extension`: String
    let kind: String
    let score: Int
    let modifiedAt: String
    let size: Int
    let excerpt: [String]
}

enum StudySyncLoader {
    static let liveURL = URL(string: "http://127.0.0.1:8787/study-sync-snapshot.json")!

    static func loadBundled() throws -> StudySyncSnapshot {
        guard let url = Bundle.main.url(forResource: "StudySyncSnapshot", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }
        let data = try Data(contentsOf: url)
        return try decode(data)
    }

    static func loadLive() async throws -> StudySyncSnapshot {
        var request = URLRequest(url: liveURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 2
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decode(data)
    }

    private static func decode(_ data: Data) throws -> StudySyncSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StudySyncSnapshot.self, from: data)
    }
}

struct StudySyncPanel: View {
    @State private var snapshot: StudySyncSnapshot?
    @State private var sourceLabel = "内置快照"
    @State private var message = "正在读取同步快照"
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "固定路径同步", subtitle: "从 C310 / E320 / 总控目录挑选进度数据")

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(sourceLabel, systemImage: sourceLabel == "实时服务" ? "dot.radiowaves.left.and.right" : "shippingbox")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(sourceLabel == "实时服务" ? AppTheme.green : AppTheme.primary)
                    Spacer()
                    Button {
                        Task { await refresh(preferLive: true) }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRefreshing)
                }

                if let snapshot {
                    metricRow(snapshot)
                    sourceList(snapshot)
                    suggestedTasks(snapshot)
                    selectedFileList(snapshot)
                } else {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .task {
            await refresh(preferLive: true)
        }
    }

    private func refresh(preferLive: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }

        if preferLive {
            do {
                snapshot = try await StudySyncLoader.loadLive()
                sourceLabel = "实时服务"
                message = "已从本地同步服务读取最新数据"
                return
            } catch {
                message = "实时服务未开启，显示 App 内置快照"
            }
        }

        do {
            snapshot = try StudySyncLoader.loadBundled()
            sourceLabel = "内置快照"
        } catch {
            snapshot = nil
            message = "还没有同步快照，请先运行 tools/sync_study_sources.mjs --write"
        }
    }

    private func metricRow(_ snapshot: StudySyncSnapshot) -> some View {
        HStack(spacing: 8) {
            syncMetric("文件", "\(snapshot.metrics.selectedFiles)", "doc.text")
            syncMetric("任务", "\(snapshot.metrics.totalTasks)", "checklist")
            syncMetric("未完成", "\(snapshot.metrics.openTasks)", "exclamationmark.circle")
        }
    }

    private func syncMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func sourceList(_ snapshot: StudySyncSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("来源目录")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryText)
            ForEach(snapshot.sources) { source in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: source.exists ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(source.exists ? AppTheme.green : AppTheme.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("扫描 \(source.filesScanned) 个文件，选中 \(source.selectedFiles) 个")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private func suggestedTasks(_ snapshot: StudySyncSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("同步到的未完成项")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryText)
            ForEach(snapshot.suggestedToday.prefix(5)) { task in
                HStack(alignment: .top, spacing: 8) {
                    Text(task.courseCode)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(task.courseCode.contains("E320") ? AppTheme.primary : AppTheme.orange, in: Capsule())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.caption)
                            .foregroundStyle(AppTheme.ink)
                        Text("\(task.sourceTitle):\(task.line)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private func selectedFileList(_ snapshot: StudySyncSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选中的进度文件")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryText)
            ForEach(snapshot.selectedFiles.prefix(6)) { file in
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(file.relativePath)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                    if let first = file.excerpt.first {
                        Text(first)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                }
                .padding(8)
                .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
