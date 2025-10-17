//
//  CallBlockerWidgetView.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
//

import UIKit
import WebKit
import CallKit

public class CallBlockerWidgetView: UIView, WKScriptMessageHandler, WKNavigationDelegate {

    public var webView: WKWebView!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    private func setupWebView() {
        let cfg = WKWebViewConfiguration()
        if #available(iOS 14.0, *) {
            let prefs = WKWebpagePreferences()
            prefs.allowsContentJavaScript = true
            cfg.defaultWebpagePreferences = prefs
        } else {
            cfg.preferences.javaScriptEnabled = true
        }

        cfg.userContentController.add(self, name: "CallBlockerBridge")
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        loadWidgetHtml()
    }

    public func loadWidgetHtml() {
        if let url = Bundle(for: CallBlockerWidgetView.self).url(forResource: "widget", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.loadHTMLString("<html><body>Widget non trovato</body></html>", baseURL: nil)
        }
    }

    private func callJS(_ js: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func callJS_updateStatus(active: Bool) {
        callJS("updateStatusCallback(\(active ? "true" : "false"))")
    }

    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String:Any], let action = body["action"] as? String else { return }
        switch action {
        case "getCallScreeningStatusAsync": getCallScreeningStatusAsync()
        case "requestRole": requestRole()
        case "openServiceUI": openServiceUI()
        default: break
        }
    }

    private func getCallScreeningStatusAsync() {
        let extensionID = MassimaTranquillitaSDK.EXTENSION_ID
        if #available(iOS 11.0, *) {
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionID) { status, _ in
                self.callJS_updateStatus(active: status == .enabled)
            }
        } else {
            callJS_updateStatus(active: false)
        }
    }

    private func requestRole() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }

    private func openServiceUI() {
        if let url = Bundle(for: CallBlockerWidgetView.self).url(forResource: "widget", withExtension: "html") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        callJS("window.CallBlockerBridgeReady = true;")
    }
}
