import UIKit
import SweetUIKit

class HomeController: UIViewController {
    var appsAPIClient: AppsAPIClient
    var ethereumAPIClient: EthereumAPIClient

    var apps = [TokenContact]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alwaysBounceVertical = true
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = Theme.viewBackgroundColor

        view.register(HomeItemCell.self)

        return view
    }()

    lazy var containerView: HomeContainerView = {
        let view = HomeContainerView(withAutoLayout: true)
        
        return view
    }()

    init(appsAPIClient: AppsAPIClient = .shared, ethererumAPIClient: EthereumAPIClient = .shared) {
        self.appsAPIClient = appsAPIClient
        self.ethereumAPIClient = ethererumAPIClient

        super.init(nibName: nil, bundle: nil)

        self.updateBalance()

        NotificationCenter.default.addObserver(self, selector: #selector(updateBalance), name: .ethereumPaymentConfirmationNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"

        self.view.backgroundColor = Theme.borderColor

        self.view.addSubview(self.containerView)
        self.view.addSubview(self.collectionView)

        self.containerView.set(height: 230)
        self.containerView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.containerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.containerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        // TODO: adjust insets for full content
        self.collectionView.contentInset = UIEdgeInsetsMake(12, 12, 0, 0)
        self.collectionView.topAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 12).isActive = true
        self.collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        self.appsAPIClient.getFeaturedApps { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.apps = apps
        }
    }

    func updateBalance(_ notification: Notification? = nil) {
        guard let user = User.current else {
            self.containerView.balance = NSDecimalNumber.zero

            return
        }
        
        self.ethereumAPIClient.getBalance(address: user.paymentAddress) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.containerView.balance = balance
            }
        }
    }
}

extension HomeController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.apps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(HomeItemCell.self, for: indexPath)
        let app = self.apps[indexPath.row]
        cell.app = app

        return cell
    }
}

extension HomeController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}

extension HomeController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let app = self.apps[indexPath.row]
        let appController = AppController(app: app)
        self.navigationController?.pushViewController(appController, animated: true)
    }
}
