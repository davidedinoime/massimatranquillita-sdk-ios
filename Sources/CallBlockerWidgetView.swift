//
//  CallBlockerWidgetView.swift
//  MassimaTranquillitaSDK
//
//  Created by Davide Dinoi on 17/10/25.
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
        guard let body = message.body as? [String:Any], let action = body["method"] as? String else { return }
        switch action {
        case "getCallScreeningStatusAsync": getCallScreeningStatusAsync()
        case "requestRole": requestRole()
        case "openServiceUI": openServiceUI()
        default: break
        }
    }

    private func getCallScreeningStatusAsync() {
        guard let extensionID = MassimaTranquillitaSDK.currentExtensionID else {
            callJS_updateStatus(active: false)
            return
        }
        
        if #available(iOS 11.0, *) {
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionID) { [weak self] status, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Errore ottenendo stato estensione: \(error.localizedDescription)")
                        self?.callJS_updateStatus(active: false)
                        return
                    }
                    self?.callJS_updateStatus(active: status == .enabled)
                }
            }
        } else {
            callJS_updateStatus(active: false)
        }
    }

    private func openServiceUI() {
        DispatchQueue.main.async {
            guard let topVC = UIApplication.shared.topViewController() else {
                print("❌ Nessun ViewController per presentare la WebView")
                return
            }

            let webVC = CallBlockerWebViewController()
            webVC.modalPresentationStyle = .formSheet

            // 👉 Adesso loadURL salva l'URL e lo carica in viewDidLoad
            if let url = URL(string: "http://192.168.1.226:3000/") {
                webVC.loadURL(url)
            }

            topVC.present(webVC, animated: true)
        }
    }
    
    // MARK: - Correzione Logica e Sintassi di requestRole()
    private func requestRole() {
        DispatchQueue.main.async {
            guard let topVC = UIApplication.shared.topViewController() else {
                print("❌ Nessun ViewController per presentare l'Alert di richiesta ruolo")
                return
            }
            
            let alert = UIAlertController(
                title: "Attiva blocco chiamate",
                message: "Per abilitare il blocco chiamate, devi attivare l'estensione Massima Tranquillità nelle impostazioni di iOS.",
                preferredStyle: .alert
            )
            
            // La chiusura non è necessaria qui, perché l'alert è modale.
            // L'eventuale callback a JS per informare l'utente va gestito dopo il ritorno dalle Impostazioni.
            alert.addAction(UIAlertAction(title: "Annulla", style: .cancel) { _ in
                // Azione da eseguire all'annullamento (es. notificare JS)
            })
            
            alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                // Azione da eseguire dopo aver aperto le impostazioni (es. notificare JS)
            })
            
            topVC.present(alert, animated: true)
        }
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        callJS("window.CallBlockerBridgeReady = true;")
    }
}

// ----------------------------------------------------------------------


// MARK: - Estensione UIApplication (Spostata fuori dalla classe per coerenza)
extension UIApplication {
    func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
