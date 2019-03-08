//ISSUES:
//crashes when keyboard is out sometimes?
//when sideways, area next to notch is clear (happens with others)
//weird dismiss behavior when sideways (happens with others)
//images flicker when scrolled fast
//no image for the app
//no loading spinner in the main part when actually loading

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
    var allSets = [CardSet]()
    
    var searchActive = false
    
    override func viewDidLoad() {
        cardCollectionView.delegate = self
        cardCollectionView.dataSource = self
        magic.fetchPageSize = "900"
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
        requestPresentationStyle(.compact)
        prepareText(cell: cell)
    }
    
    func getDefaultCards() {
        showLoadingSpinner()
        let name = SetSearchParameter(parameterType: .name, value: "")
        magic.fetchSets([name], completion: { (sets, error) in
            self.allSets = self.handleAPIData(error: error, sets: sets)
            print(self.allSets)
            let currentSet = self.getMostRecentSet(sets: self.allSets)
            print(currentSet)
            self.magic.generateBoosterForSet(currentSet, completion: { (cards, error) in
                self.hideLoadingSpinnerAsync()
                self.defaultCards = self.handleAPIData(error: error, cards: cards)
                self.reloadTableAsync()
            })
        })
    }
    
    func getMostRecentSet(sets: [CardSet]) -> String {
        var expansionSetsWithDates = [CardSet]()
        for set in sets {
            if(set.releaseDate != nil && set.type == "expansion") {
                expansionSetsWithDates.append(set)
            }
        }
        
        print(expansionSetsWithDates)
        
        if(expansionSetsWithDates.isEmpty) {
            return "KTK";
        }
        
        let sortedSets = expansionSetsWithDates.sorted { $0.releaseDate! > $1.releaseDate! }
        return sortedSets[0].code!
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
        var completeCards = [Card]()
        for card in unwrappedCards {
            if card.imageUrl != nil {
                completeCards.append(card)
            }
        }
        return completeCards
    }
    
    func handleAPIData(error bundle: Error?, sets setArray: [CardSet]?) -> [CardSet] {
        if let error = bundle {
            print(error)
            return [CardSet]()
        }
        guard let unwrappedSets = setArray else {
            self.handleLoadingError()
            return [CardSet]()
        }
        var completeSets = [CardSet]()
        for set in unwrappedSets {
            if set.releaseDate != nil {
                completeSets.append(set)
            }
        }
        return completeSets
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
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupCollectionView(){
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 2.0
        layout.minimumInteritemSpacing = 2.0
        layout.columnCount = 3
        cardCollectionView.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
        cardCollectionView.alwaysBounceVertical = true
        cardCollectionView.collectionViewLayout = layout
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.becomeFirstResponder()
        requestPresentationStyle(.expanded)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.endEditing(true)
        //searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.endEditing(true)
        //searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.endEditing(true)
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
        let keyboardSize = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size
        let toolbarSize = cardCollectionView.convert(cardCollectionView.bounds, to: nil)

        // Step 2: Adjust the bottom content inset of your scroll view by the keyboard height.
        let contentInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: keyboardSize.height - toolbarSize.minY + 14, right: 0.0)
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
