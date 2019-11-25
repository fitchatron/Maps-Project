//
//  LocationsCaroselController.swift
//  Maps Project
//
//  Created by James Fitch on 16/11/19.
//  Copyright © 2019 Fitchatron. All rights reserved.
//

import UIKit
import LBTATools
import MapKit

class LocationCell: LBTAListCell<MKMapItem> {
    
    override var item: MKMapItem! {
        didSet {
            label.text = item.name
            addressLabel.text = item.address()
            latLongLabel.text = "\(item.placemark.coordinate.latitude), \(item.placemark.coordinate.longitude)"
        }
    }
    let label = UILabel(text: "Location", font: .boldSystemFont(ofSize: 16))
    let addressLabel = UILabel(text: "Address", font: .systemFont(ofSize: 14), textColor: .darkGray, textAlignment: .left, numberOfLines: 0)
    let latLongLabel = UILabel(text: "lat, long", font: .systemFont(ofSize: 14), textColor: .lightGray, textAlignment: .left, numberOfLines: 0)
    
    override func setupViews() {
        backgroundColor = .white
        setupShadow(opacity: 0.3, radius: 5, offset: .zero, color: .black)
        layer.cornerRadius = 5
        
        //TODO: - format to be nicer in stackView
        stack(label, addressLabel, latLongLabel).withMargins(.allSides(16))
    }
}

class LocationsCaroselController: LBTAListController<LocationCell, MKMapItem> {
    
    weak var mainController: MainController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let annotations = mainController?.mapView.annotations
        
        annotations?.forEach({ (annotation) in
            guard let customAnnotation = annotation as? MainController.CustomMapItemAnnotation else { return }
            if customAnnotation.mapItem?.name == self.items[indexPath.item].name {
                mainController?.mapView.selectAnnotation(annotation, animated: true)
            }
        })
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

extension LocationsCaroselController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 64, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
}
