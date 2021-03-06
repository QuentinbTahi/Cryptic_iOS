//
//  APIConnector+Places.swift
//  Marks
//
//  Created by Quentin Beaudouin on 02/11/2016.
//  Copyright © 2016 Quentin Beaudouin. All rights reserved.
//

import Alamofire
import CoreLocation

//************************************
// MARK: - Place
//************************************

extension APIConnector {
    
    
    static func getLocation(locationID:String, completion:@escaping (CGLocation?) -> Void){

        var queryParams:[String:String] = [:]
        
        if let accessT = APIConnector.userSession?.accessToken {
            queryParams["access_token"] = accessT
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        sessionManager.request(self.absoluteURLString(path: "locations/\(locationID)"), parameters: queryParams).responseJSON { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            print(response.result.value)
            if let jsonDict = response.result.value as? [String: AnyObject], jsonDict["error"] == nil{
                
                let place = CGLocation(dictionary: jsonDict)
                completion(place)
                
                
            }
            else{
                completion(nil)
            }
        }
        
        
    }
    
    static func postMessage(_ message:CGMessage, toLocation location:CGLocation, completion:@escaping (_ success:Bool) -> Void){
        
        var messageDict : [String:String] = [
            "text" : message.text,
            "tag": message.tag,
            "firebaseDBchannelID": message.firebaseDBchannelID
        ]
        
        if let lastLoc = LocationManager.shared.lastLocation {
            print(lastLoc)
            let distance = lastLoc.distance(from: CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            messageDict["postDistance"] = "\(distance)"
        }
        
        
        let locationDict : [String:AnyObject] = [
            CGLocation.kGoogleId: location.googlePlaceId as AnyObject,
            CGLocation.kGoogleName: location.googleName as AnyObject,
            CGLocation.kPosition: ["type":"Point", CGLocation.kCoordInPosition:[location.coordinate.longitude,location.coordinate.latitude]] as AnyObject, //Mongo takes [lng, lat]?
            CGLocation.kGoogleAdress:location.googleAddress as AnyObject,
            ]
        
        var queryParams:[String:AnyObject] = [
            "location":locationDict as AnyObject,
            "message":messageDict as AnyObject,
        ]
        
        if let accessT = APIConnector.userSession?.accessToken { queryParams["access_token"] = accessT as AnyObject }
        
        //        let tagsString = (tags == nil) ? nil:tags!.joined(separator: ",")
        
        //        if tagsString != nil { queryParams["tags"] = tagsString! }
        
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _ = sessionManager.request(self.absoluteURLString(path: location.googlePlaceId+"/message"), method: .post, parameters: queryParams, encoding: JSONEncoding.default).responseJSON { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            if succededRequest(response: response) {
                completion(true)
            }
            else {
                completion(false)
            }
        }
        

    }
    
}


//************************************
// MARK: - Places
//************************************

extension APIConnector {
    
    
    static func getLocations(viewport:Viewport, completion:@escaping ([CGLocation]?, _ canceled:Bool) -> Void) -> Alamofire.DataRequest? {
        
        var queryParams:[String:String] = [
            "limit" : "100",
            "northeast":"\(viewport.northEast.latitude),\(viewport.northEast.longitude)",
            "southwest":"\(viewport.southWest.latitude),\(viewport.southWest.longitude)",
        ]
        
        if let accessT = APIConnector.userSession?.accessToken { queryParams["access_token"] = accessT }
        
//        let tagsString = (tags == nil) ? nil:tags!.joined(separator: ",")
        
//        if tagsString != nil { queryParams["tags"] = tagsString! }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let request = sessionManager.request(self.absoluteURLString(path: "search/locations"), parameters: queryParams).responseJSON { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            if let rawPlaces = response.result.value as? [[String: AnyObject]]{
                
                var buildPlaces = [CGLocation]()
                
                for rawPlace in rawPlaces {
                    let place = CGLocation(dictionary: rawPlace)
                    buildPlaces.append(place)
                }
                completion(buildPlaces, false)
 
            }
            else if let error = response.error as NSError?, error.code == -999 {
                completion(nil, true)
            }
            else{
                completion(nil, false)
            }
        }
        
        return request
    }
    
}



