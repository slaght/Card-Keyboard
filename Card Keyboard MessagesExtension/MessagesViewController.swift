
import UIKit
import Messages
import MTGSDKSwift

class MessagesViewController: MSMessagesAppViewController,  UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, CHTCollectionViewDelegateWaterfallLayout {
    
    @IBOutlet weak var cardCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    let magic = Magic()
    var defaultCards = [Card]()
    var filteredCards = [Card]()
    
    var searchActive = false
    
    override func viewDidLoad() {
        cardCollectionView.delegate = self
        cardCollectionView.dataSource = self
        magic.fetchPageSize = "100"
        getDefaultCards()
        setupCollectionView()
        setupSearchView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(searchActive) {
            return filteredCards.count
        }
        return defaultCards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardViewCell", for: indexPath) as! CardViewCell
        cell.setupBorder()
        if(searchActive) {
            cell.set(card: filteredCards[indexPath.row])
        } else {
            cell.set(card: defaultCards[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let imageSize = CGSize(width: 223, height: 311)
        return imageSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CardViewCell
        prepareText(cell: cell)
    }
    
    func getDefaultCards() {
        showLoadingSpinner()
        magic.generateBoosterForSet("AER", completion: { (cards, error) in
            self.hideLoadingSpinnerAsync()
            
            self.defaultCards = self.handleAPIData(error: error, cards: cards)
            self.reloadTableAsync()
        })
    }
    
    func showLoadingSpinner() {
        loadingSpinner.isHidden = false
    }
    
    func hideLoadingSpinnerAsync() {
        DispatchQueue.main.async {
            self.loadingSpinner.isHidden = true
        }
    }
    
    func handleAPIData(error bundle: Error?, cards cardArray: [Card]?) -> [Card] {
        if let error = bundle {
            print(error)
            return [Card]()
        }
        guard let unwrappedCards = cardArray else {
            self.handleLoadingError()
            return [Card]()
        }
        return unwrappedCards
    }
    
    func reloadTableAsync() {
        DispatchQueue.main.async {
            self.cardCollectionView.reloadData()
        }
    }
    
    func handleLoadingError() {}
    
    func setupSearchView() {
        searchBar.delegate = self
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardDidShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupCollectionView(){
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 2.0
        layout.minimumInteritemSpacing = 2.0
        layout.columnCount = 3
        cardCollectionView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        cardCollectionView.alwaysBounceVertical = true
        cardCollectionView.collectionViewLayout = layout
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCards = [Card]()
        if(searchText == "") {
            searchActive = false
            reloadTableAsync()
            return
        }
        searchActive = true
        makeSearchRequest(for: searchText)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        // Step 1: Get the size of the keyboard.
        let keyboardSize = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size
        let toolbarSize = cardCollectionView.convert(cardCollectionView.bounds, to: nil)

        // Step 2: Adjust the bottom content inset of your scroll view by the keyboard height.
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height - toolbarSize.minY + 14, 0.0)
        cardCollectionView.contentInset = contentInsets;
        cardCollectionView.scrollIndicatorInsets = contentInsets;
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        cardCollectionView.contentInset = contentInsets
        cardCollectionView.scrollIndicatorInsets = contentInsets
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
    }
    
    func makeSearchRequest(for query: String) {
        showLoadingSpinner()
        let name = CardSearchParameter(parameterType: .name, value: query)
        magic.fetchCards([name]) { cards, error in
            self.hideLoadingSpinnerAsync()
            if(query == self.searchBar.text!) {
                self.filteredCards = self.handleAPIData(error: error, cards: cards)
                self.reloadTableAsync()
            }
        }
    }
    
    func prepareText(cell: CardViewCell) {
        let message = MSMessage()
        message.layout = getMessageTemplate(for: cell)
        activeConversation?.insert(message, completionHandler: { (error) in })
    }
    
    func getMessageTemplate(for cell: CardViewCell) -> MSMessageTemplateLayout {
        let template = MSMessageTemplateLayout()
        template.image = cell.imageView.image
        template.imageTitle = cell.card.name
        template.caption = cell.card.flavor
        return template
    }
}
