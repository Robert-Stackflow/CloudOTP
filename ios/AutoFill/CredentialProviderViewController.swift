import UIKit
import AuthenticationServices
import LocalAuthentication

@available(iOS 18.0, *)
final class CredentialProviderViewController: ASCredentialProviderViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
  private let table = UITableView(frame: .zero, style: .insetGrouped)
  private let search = UISearchController(searchResultsController: nil)
  private var records: [AutoFillToken] = []
  private var visible: [AutoFillToken] = []
  private var authentication: LAContext?
  private var configured = false
  private var pendingID: String?
  private var serviceIdentifiers: [ASCredentialServiceIdentifier] = []
  private var chinese: Bool { Locale.preferredLanguages.first?.hasPrefix("zh") == true }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    let navigation = UINavigationBar()
    navigation.translatesAutoresizingMaskIntoConstraints = false
    let item = UINavigationItem(title: "CloudOTP")
    item.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    navigation.items = [item]
    table.translatesAutoresizingMaskIntoConstraints = false
    table.dataSource = self
    table.delegate = self
    table.register(UITableViewCell.self, forCellReuseIdentifier: "token")
    search.searchResultsUpdater = self
    search.obscuresBackgroundDuringPresentation = false
    search.searchBar.placeholder = chinese ? "搜索账户或服务" : "Search accounts or services"
    search.searchBar.sizeToFit()
    table.tableHeaderView = search.searchBar
    view.addSubview(navigation)
    view.addSubview(table)
    NSLayoutConstraint.activate([
      navigation.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      navigation.leadingAnchor.constraint(equalTo: view.leadingAnchor), navigation.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: navigation.bottomAnchor), table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      table.leadingAnchor.constraint(equalTo: view.leadingAnchor), table.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
  }
  override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    self.serviceIdentifiers = serviceIdentifiers
    unlock()
  }
  override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    self.serviceIdentifiers = serviceIdentifiers
    unlock()
  }
  override func provideCredentialWithoutUserInteraction(for credentialRequest: ASCredentialRequest) {
    // Never return a secret based solely on device-unlocked state.
    extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userInteractionRequired.rawValue))
  }
  override func prepareInterfaceToProvideCredential(for credentialRequest: ASCredentialRequest) {
    guard credentialRequest is ASOneTimeCodeCredentialRequest else {
      extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.credentialIdentityNotFound.rawValue)); return
    }
    pendingID = credentialRequest.credentialIdentity.recordIdentifier
    unlock()
  }
  override func prepareInterfaceForExtensionConfiguration() {
    loadViewIfNeeded()
    configured = true
    let button = UIButton(type: .system)
    button.setTitle(chinese ? "完成：返回 CloudOTP 启用并同步令牌" : "Done — enable and sync tokens in CloudOTP", for: .normal)
    button.addTarget(self, action: #selector(finishConfiguration), for: .touchUpInside)
    button.frame = CGRect(x: 16, y: 0, width: 340, height: 100)
    table.tableHeaderView = button
  }
  @objc private func finishConfiguration() { extensionContext.completeExtensionConfigurationRequest() }
  private func unlock() {
    loadViewIfNeeded()
    guard authentication == nil else { return }
    let context = LAContext()
    authentication = context
    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: chinese ? "验证身份以填充 CloudOTP 验证码" : "Verify your identity to fill a CloudOTP code") { [weak self] success, _ in
      DispatchQueue.main.async {
        guard let self = self else { return }
        guard success else { self.cancel(); return }
        do {
          self.records = try AutoFillVault.load()
          self.visible = self.records.sorted { self.rank($0) < self.rank($1) }
          if let id = self.pendingID, let token = self.records.first(where: { $0.uid == id }) {
            self.fill(token)
          } else {
            self.table.reloadData()
            if self.records.isEmpty {
              let label = UILabel()
              label.text = self.chinese ? "请先在 CloudOTP 的“更多 → 实验室”启用自动填充并同步 TOTP 令牌。" : "Enable AutoFill and sync TOTP tokens in CloudOTP’s More → Laboratory."
              label.numberOfLines = 0
              label.textAlignment = .center
              self.table.backgroundView = label
            }
          }
        } catch { self.showFailure() }
      }
    }
  }
  private func rank(_ token: AutoFillToken) -> String {
    let matches = serviceIdentifiers.contains { identifier in
      let host = URL(string: identifier.identifier)?.host ?? identifier.identifier
      guard let domain = token.domain else { return false }
      let lowered = host.lowercased()
      return lowered == domain || lowered.hasSuffix("." + domain)
    }
    return (matches ? "0" : "1") + token.label.lowercased()
  }
  func updateSearchResults(for searchController: UISearchController) {
    let query = searchController.searchBar.text ?? ""
    visible = records.filter { query.isEmpty || $0.label.localizedCaseInsensitiveContains(query) }.sorted { rank($0) < rank($1) }
    table.reloadData()
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visible.count }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "token", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = visible[indexPath.row].issuer
    config.secondaryText = visible[indexPath.row].account
    config.image = UIImage(systemName: "key.fill")
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { fill(visible[indexPath.row]) }
  private func fill(_ token: AutoFillToken) {
    guard let code = OTPGenerator.code(secret: token.secret, algorithm: token.algorithm, digits: token.digits, period: token.period) else { showFailure(); return }
    records = []; visible = []; authentication?.invalidate(); authentication = nil
    extensionContext.completeOneTimeCodeRequest(using: ASOneTimeCodeCredential(code: code), completionHandler: nil)
  }
  private func showFailure() {
    let alert = UIAlertController(title: "CloudOTP", message: chinese ? "无法读取验证码，请打开 CloudOTP 重新同步。" : "Unable to read verification codes. Open CloudOTP and sync again.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: chinese ? "取消" : "Cancel", style: .cancel) { _ in self.cancel() })
    present(alert, animated: true)
  }
  @objc private func cancel() {
    records = []; visible = []; authentication?.invalidate(); authentication = nil
    extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
  }
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    records = []; visible = []; authentication?.invalidate(); authentication = nil
  }
}
