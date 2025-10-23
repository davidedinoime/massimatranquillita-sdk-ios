//
//  Untitled.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//
import UIKit
import WebKit
import CallKit

public class CallBlockerWebViewController: UIViewController {
    
    public var webView: WKWebView!
    
    private var urlToLoad: URL?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        
        // 👉 Carica l'URL solo dopo che la webView è stata inizializzata
        if let url = urlToLoad {
            loadURL(url)
            // Resetta per evitare ricaricamenti non voluti se il VC viene riusato
            urlToLoad = nil
        }
    }
    
    public func loadURL(_ url: URL) {
        if isViewLoaded {
            // Se la vista è già caricata (e la webView è viva), carica subito
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            // Altrimenti, salva l'URL per caricarlo in viewDidLoad
            urlToLoad = url
        }
    }
    
    public func loadWidgetHTML(named name: String = "widget") {
        if let url = Bundle(for: CallBlockerWebViewController.self).url(forResource: name, withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.loadHTMLString("<html><body>Widget non trovato</body></html>", baseURL: nil)
        }
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "CallBlockerBridge")
        config.userContentController = contentController
        
        if #available(iOS 14.0, *) {
            let prefs = WKWebpagePreferences()
            prefs.allowsContentJavaScript = true
            config.defaultWebpagePreferences = prefs
        } else {
            config.preferences.javaScriptEnabled = true
        }
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func callJS(_ js: String) {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    private func callJS_updateStatus(active: Bool) {
        callJS("setCallScreeningStatus(\(active ? "true" : "false"));")
    }
    
    private func escapeForJS(_ s: String) -> String {
        return s.replacingOccurrences(of: "'", with: "\\'")
    }
    
    private func getCallScreeningStatusAsync() {
        let extensionID = MassimaTranquillitaSDK.EXTENSION_ID
        if #available(iOS 11.0, *) {
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionID) { status, _ in
                let active = status == .enabled
                self.callJS_updateStatus(active: active)
            }
        } else {
            callJS_updateStatus(active: false)
        }
    }
    
    private func requestRole() {
        DispatchQueue.main.async {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.getCallScreeningStatusAsync()
            }
        }
    }
    
    private func openServiceUI(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - WKScriptMessageHandler
extension CallBlockerWebViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let method = body["method"] as? String else { return }
        
        switch method {
        case "blockNumber":
            if let number = body["number"] as? String {
                print("Numero da bloccare: \(number)")
                callJS("onNumberBlocked('\(escapeForJS(number))');")
            }
        case "requestRole": requestRole()
        case "openServiceUI":
            if let urlString = body["url"] as? String { openServiceUI(urlString: urlString) }
        case "closeWebView": dismiss(animated: true)
        case "getCallScreeningStatusAsync": getCallScreeningStatusAsync()
        default: break
        }
    }
}

// MARK: - WKNavigationDelegate
extension CallBlockerWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        callJS("window.CallBlockerBridgeReady = true;")
    }
}
