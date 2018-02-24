//
//  ViewController.swift
//  Pulley
//
//  Created by Brendan Lee on 7/6/16.
//  Copyright © 2016 52inc. All rights reserved.
//

import UIKit
import MapKit

class PrimaryContentViewController: UIViewController {
    

    @IBOutlet weak var mapView: SearchResultMapView!
    @IBOutlet var controlsContainer: UIView!
    
    @IBOutlet weak var locButton: UIButton!
    /**
     * IMPORTANT! If you have constraints that you use to 'follow' the drawer (like the temperature label in the demo)...
     * Make sure you constraint them to the bottom of the superview and NOT the superview's bottom margin. Double click the constraint, and you can change it in the dropdown in the right-side panel. If you don't, you'll have varying spacings to the drawer depending on the device.
     */
    @IBOutlet var locButtonBotConstraint: NSLayoutConstraint!
    fileprivate let locButtonBotDistance: CGFloat = 8.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        controlsContainer.layer.cornerRadius = 10.0
        locButton.layer.cornerRadius = 10.0
        
        
        mapView.mapReadyAction = { [weak self] in self?.callAPILocations() }
        mapView.mapRegionDidChangeAction = { [weak self] in self?.callAPILocations() }
        mapView.mapDeselectAnnotationAction = { [weak self] annotationView in self?.locationDeselected() }
        mapView.mapSelectAnnotationAction = { [weak self] annotationView in
            if let annot = annotationView.annotation as? PlaceAnnotation  {
                self?.locationSelected(annot.place)
            }

        }
        
        
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Customize Pulley in viewWillAppear, as the view controller's viewDidLoad will run *before* Pulley's and some changes may be overwritten.
        if let drawer = parent as? PulleyViewController {
            // Uncomment if you want to change the visual effect style to dark. Note: The rest of the sample app's UI isn't made for dark theme. This just shows you how to do it.
            // drawer.drawerBackgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            
            // We want the 'side panel' layout in landscape iPhone / iPad, so we set this to 'automatic'. The default is 'bottomDrawer' for compatibility with older Pulley versions.
            drawer.displayMode = .automatic
        }
    }
    
}

//************************************
// MARK: - Actions
//************************************

extension PrimaryContentViewController {
    
    @IBAction func locationButtonClicked(sender: AnyObject) {
        
        if let mainVC = parent as? PulleyViewController, let drawerVC = mainVC.drawerContentViewController as? DrawerContentViewController {
            
            if let coord = LocationManager.shared.lastKnownCoord {
                mapView.mapView.centerOn(coord: coord, radius: MapFunctions.defaultRegionRadius, animated: true)
                drawerVC.autofillSearchBar()
            }
            
            
        }
    }
    
    func selectAnnotation(location:CGLocation) {
        
        for annot in mapView.mapView.annotations {
            if let pAnnot = annot as? PlaceAnnotation {
                if pAnnot.place == location {
                    mapView.mapView.selectAnnotation(pAnnot, animated: true)
                    return
                }
            }
        }
        
    }
    
    func locationSelected(_ location:CGLocation) {
        
        if let mainVC = parent as? PulleyViewController {
            mainVC.setDrawerPosition(position: .partiallyRevealed, animated: true)
            if let drawerVC = mainVC.drawerContentViewController as? DrawerContentViewController {
                drawerVC.currentLocation = location
            }
        }
    }
    
    func locationDeselected() {
        
        if let mainVC = parent as? PulleyViewController {
            mainVC.setDrawerPosition(position: .collapsed, animated: true)
            if let drawerVC = mainVC.drawerContentViewController as? DrawerContentViewController {
                drawerVC.currentLocation = nil
            }
        }
    }
    
}

//************************************
// MARK: - API Calls
//************************************

extension PrimaryContentViewController {
    
    func callAPILocations() {
        
        _ = APIConnector.getLocations(viewport: mapView.mapView.viewportVisibleAnnot(), completion: { [weak self] (locations, cancelled) in
            
            if locations == nil { return }
            
            self?.mapView.filteredPlaces = locations!
        })
        
    }
    
}

//************************************
// MARK: - Drawer Delegate
//************************************

extension PrimaryContentViewController: PulleyPrimaryContentControllerDelegate {
    
    func makeUIAdjustmentsForFullscreen(progress: CGFloat, bottomSafeArea: CGFloat) {
        guard let drawer = parent as? PulleyViewController, drawer.currentDisplayMode == .bottomDrawer else {
            controlsContainer.alpha = 1.0
            return
        }
        
        controlsContainer.alpha = 1.0 - progress
    }
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        guard drawer.currentDisplayMode == .bottomDrawer else {
            
            locButtonBotConstraint.constant = locButtonBotDistance
            return
        }
        
        if distance <= 268.0 + bottomSafeArea {
            locButtonBotConstraint.constant = distance + locButtonBotDistance
        }
        else {
            locButtonBotConstraint.constant = 268.0 + locButtonBotDistance
        }
    }
}

//************************************
// MARK: - Drawer Navigation
//************************************

extension PrimaryContentViewController {
    
    @IBAction func runPrimaryContentTransition(sender: AnyObject) {
        
//        startVerification()
        let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PrimaryTransitionTargetViewController")
        present(primaryContent, animated: true, completion: nil)
        
//        if let drawer = self.parent as? PulleyViewController {
//            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PrimaryTransitionTargetViewController")
//
//            drawer.setPrimaryContentViewController(controller: primaryContent, animated: true)
//        }
    }
}

