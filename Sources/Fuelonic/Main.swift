#if os(macOS)
import Cocoa
import WebKit
import UniformTypeIdentifiers

@main
@MainActor
struct AppMain {
    static var appDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        appDelegate = AppDelegate()
        app.delegate = appDelegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    var mainWindow: NSWindow!
    var webView: WKWebView!

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "importCSV" {
            handleImport()
        }
    }

    func handleImport() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] result in
            guard result == .OK, let url = panel.url else { return }
            self?.processFile(at: url)
        }
    }

    func processFile(at url: URL) {
        DispatchQueue.main.async { [weak self] in
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                self?.sendToWeb(with: text)
            } catch {
                self?.showError("Nie udało się odczytać pliku")
            }
        }
    }

    func sendToWeb(with text: String) {
        let base64 = Data(text.utf8).base64EncodedString()
        let js = "window._importDataBase64('\(base64)')"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func showError(_ msg: String) {
        webView.evaluateJavaScript("alert('\(msg)')", completionHandler: nil)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let contentRect = NSRect(x: 0, y: 0, width: 1280, height: 850)
        mainWindow = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        mainWindow.title = "Fuelonic"
        mainWindow.backgroundColor = NSColor(white: 1, alpha: 1)
        mainWindow.center()

        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        webView = WKWebView(frame: contentRect, configuration: config)
        webView.navigationDelegate = WebViewDelegate()
        webView.configuration.userContentController.add(self, name: "importCSV")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.white.cgColor
        webView.autoresizingMask = [.width, .height]

        let htmlPath = Bundle.main.resourceURL?.appendingPathComponent("Fuelonic.html")
        if let htmlPath = htmlPath, FileManager.default.fileExists(atPath: htmlPath.path) {
            do {
                let htmlContent = try String(contentsOf: htmlPath, encoding: .utf8)
                webView.loadHTMLString(htmlContent, baseURL: htmlPath.deletingLastPathComponent())
            } catch {
                let fallback = "<html><body style='background:#fff;color:#222;font-family:system-ui;padding:40px;text-align:center;'><h1>⚠ Fuelonic</h1><p>Błąd ładowania HTML: \(error.localizedDescription)</p></body></html>"
                webView.loadHTMLString(fallback, baseURL: nil)
            }
        } else {
            let fallback = "<html><body style='background:#fff;color:#222;font-family:system-ui;padding:40px;text-align:center;'><h1>⚠ Fuelonic</h1><p>HTML nie znaleziony</p><p style='font-size:12px;color:#999'>Bundle: \(Bundle.main.bundlePath)</p></body></html>"
            webView.loadHTMLString(fallback, baseURL: nil)
        }

        mainWindow.contentView = webView
        mainWindow.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { true }
}

class WebViewDelegate: NSObject, WKNavigationDelegate {}

#endif
