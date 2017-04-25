//
//  MainVC.swift
//  HomeSafv
//
//  Created by Alex Tan on 25/4/17.
//  Copyright © 2017 SG4207. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class MainVC: UINavigationController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    @IBOutlet var contactsView: UIView!
    @IBOutlet var mapView: UIView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var profileView: UIView!
    @IBOutlet weak var mapLocation: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    var topAnchorContraint: NSLayoutConstraint!
    let darkView = UIView.init()
    var items = [User]()

    func customization() {
        self.view.addSubview(self.darkView)
        self.darkView.backgroundColor = UIColor.black
        self.darkView.alpha = 0
        self.darkView.translatesAutoresizingMaskIntoConstraints = false
        self.darkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.darkView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.darkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.darkView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.darkView.isHidden = true
        
        let extraViewsContainer = UIView.init()
        extraViewsContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(extraViewsContainer)
        self.topAnchorContraint = NSLayoutConstraint.init(item: extraViewsContainer, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 1000)
        self.topAnchorContraint.isActive = true
        extraViewsContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        extraViewsContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        extraViewsContainer.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1).isActive = true
        extraViewsContainer.backgroundColor = UIColor.clear
        
        extraViewsContainer.addSubview(self.contactsView)
        self.contactsView.translatesAutoresizingMaskIntoConstraints = false
        self.contactsView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.contactsView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.contactsView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.contactsView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        self.contactsView.isHidden = true
        self.collectionView?.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        self.contactsView.backgroundColor = UIColor.clear
        
        extraViewsContainer.addSubview(self.profileView)
        self.profileView.translatesAutoresizingMaskIntoConstraints = false
        self.profileView.heightAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width * 0.9)).isActive = true
        let profileViewAspectRatio = NSLayoutConstraint.init(item: self.profileView, attribute: .width, relatedBy: .equal, toItem: self.profileView, attribute: .height, multiplier: 0.8125, constant: 0)
        profileViewAspectRatio.isActive = true
        self.profileView.centerXAnchor.constraint(equalTo: extraViewsContainer.centerXAnchor).isActive = true
        self.profileView.centerYAnchor.constraint(equalTo: extraViewsContainer.centerYAnchor).isActive = true
        self.profileView.layer.cornerRadius = 5
        self.profileView.clipsToBounds = true
        self.profileView.isHidden = true
        self.profilePic.layer.borderColor = GlobalVariables.purple.cgColor
        self.profilePic.layer.borderWidth = 3
        self.view.layoutIfNeeded()
        
        extraViewsContainer.addSubview(self.previewView)
        self.previewView.isHidden = true
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.previewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.previewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.previewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.previewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 3.0
        
        extraViewsContainer.addSubview(self.mapView)
        self.mapView.isHidden = true
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.mapView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.mapView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.mapView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showExtraViews(notification:)), name: NSNotification.Name(rawValue: "showExtraView"), object: nil)
        self.fetchUsers()
        self.fetchUserInfo()
        
    }
    
    func dismissExtraViews() {
        self.topAnchorContraint.constant = 1000
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.darkView.alpha = 0
            self.view.transform = CGAffineTransform.identity
        }, completion:  { (true) in
            self.darkView.isHidden = true
            self.profileView.isHidden = true
            self.contactsView.isHidden = true
            self.previewView.isHidden = true
            self.mapView.isHidden = true
            self.mapLocation.removeAnnotations(self.mapLocation.annotations)
            let vc = self.viewControllers.last
            vc?.inputAccessoryView?.isHidden = false
        })
    }
    
    func showExtraViews(notification: NSNotification)  {
        let transform = CGAffineTransform.init(scaleX: 0.94, y: 0.94)
        self.topAnchorContraint.constant = 0
        self.darkView.isHidden = false
        if let type = notification.userInfo?["viewType"] as? ShowExtraView {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                self.darkView.alpha = 0.8
                if (type == .contacts || type == .profile) {
                    self.view.transform = transform
                }
            })
            switch type {
            case .contacts:
                self.contactsView.isHidden = false
                if self.items.count == 0 {
                }
            case .profile:
                self.profileView.isHidden = false
            case .preview:
                self.previewView.isHidden = false
                self.previewImageView.image = notification.userInfo?["pic"] as? UIImage
                self.scrollView.contentSize = self.previewImageView.frame.size
            case .map:
                self.mapView.isHidden = false
                let coordinate = notification.userInfo?["location"] as? CLLocationCoordinate2D
                let annotation = MKPointAnnotation.init()
                annotation.coordinate = coordinate!
                self.mapLocation.addAnnotation(annotation)
                self.mapLocation.showAnnotations(self.mapLocation.annotations, animated: false)
            }
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.previewImageView.frame.size.height / scale
        zoomRect.size.width  = self.previewImageView.frame.size.width  / scale
        let newCenter = self.previewImageView.convert(center, from: self.scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    func fetchUsers()  {
        if let id = FIRAuth.auth()?.currentUser?.uid {
            User.downloadAllUsers(exceptID: id, completion: {(user) in
                DispatchQueue.main.async {
                    self.items.append(user)
                    self.collectionView.reloadData()
                }
            })
        }
    }
    
    func fetchUserInfo() {
        if let id = FIRAuth.auth()?.currentUser?.uid {
            User.info(forUserID: id, completion: {[weak weakSelf = self] (user) in
                DispatchQueue.main.async {
                    weakSelf?.nameLbl.text = user.name
                    weakSelf?.emailLbl.text = user.email
                    weakSelf?.profilePic.image = user.profilePic
                    weakSelf = nil
                }
            })
        }
    }
    
    @IBAction func doubleTapGesture(_ sender: UITapGestureRecognizer) {
        if self.scrollView.zoomScale == 1 {
            self.scrollView.zoom(to: zoomRectForScale(scale: self.scrollView.maximumZoomScale, center: sender.location(in: sender.view)), animated: true)
        } else {
            self.scrollView.setZoomScale(1, animated: true)
        }
    }
    
    @IBAction func closeView(_ sender: Any) {
        self.dismissExtraViews()
    }
    
    @IBAction func logOutUser(_ sender: Any) {
        User.logOutUser { (status) in
            if status == true {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.items.count == 0 {
            return 1
        } else {
            return self.items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.items.count == 0 {
            let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: "Empty Cell", for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ContactsCVCell
            cell.profilePic.image = self.items[indexPath.row].profilePic
            cell.nameLabel.text = self.items[indexPath.row].name
            cell.profilePic.layer.borderWidth = 2
            cell.profilePic.layer.borderColor = GlobalVariables.purple.cgColor
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.items.count > 0 {
            self.dismissExtraViews()
            let userInfo = ["user": self.items[indexPath.row]]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showUserMessages"), object: nil, userInfo: userInfo)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.items.count == 0 {
            return self.collectionView.bounds.size
        } else {
            if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
                let width = (0.3 * UIScreen.main.bounds.height)
                let height = width + 30
                return CGSize.init(width: width, height: height)
            } else {
                let width = (0.3 * UIScreen.main.bounds.width)
                let height = width + 30
                return CGSize.init(width: width, height: height)
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.previewImageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.view.transform = CGAffineTransform.identity
    }    

}
