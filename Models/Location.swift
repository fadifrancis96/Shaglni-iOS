//
//  Location.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import CoreLocation

struct CityLocation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let nameHebrew: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CityLocation, rhs: CityLocation) -> Bool {
        lhs.id == rhs.id
    }
}

// Major Israeli Cities with Coordinates
struct IsraeliCities {
    static let all: [CityLocation] = [
        // Major Cities
        CityLocation(name: "Jerusalem", nameHebrew: "ירושלים", coordinate: CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)),
        CityLocation(name: "Tel Aviv", nameHebrew: "תל אביב", coordinate: CLLocationCoordinate2D(latitude: 32.0853, longitude: 34.7818)),
        CityLocation(name: "Haifa", nameHebrew: "חיפה", coordinate: CLLocationCoordinate2D(latitude: 32.7940, longitude: 34.9896)),
        CityLocation(name: "Rishon LeZion", nameHebrew: "ראשון לציון", coordinate: CLLocationCoordinate2D(latitude: 31.9730, longitude: 34.7925)),
        CityLocation(name: "Petah Tikva", nameHebrew: "פתח תקווה", coordinate: CLLocationCoordinate2D(latitude: 32.0878, longitude: 34.8878)),
        CityLocation(name: "Ashdod", nameHebrew: "אשדוד", coordinate: CLLocationCoordinate2D(latitude: 31.8044, longitude: 34.6553)),
        CityLocation(name: "Netanya", nameHebrew: "נתניה", coordinate: CLLocationCoordinate2D(latitude: 32.3215, longitude: 34.8532)),
        CityLocation(name: "Beersheba", nameHebrew: "באר שבע", coordinate: CLLocationCoordinate2D(latitude: 31.2518, longitude: 34.7913)),
        CityLocation(name: "Holon", nameHebrew: "חולון", coordinate: CLLocationCoordinate2D(latitude: 32.0117, longitude: 34.7742)),
        CityLocation(name: "Ramat Gan", nameHebrew: "רמת גן", coordinate: CLLocationCoordinate2D(latitude: 32.0719, longitude: 34.8237)),
        
        // Central Region
        CityLocation(name: "Rehovot", nameHebrew: "רחובות", coordinate: CLLocationCoordinate2D(latitude: 31.8914, longitude: 34.8078)),
        CityLocation(name: "Bat Yam", nameHebrew: "בת ים", coordinate: CLLocationCoordinate2D(latitude: 32.0167, longitude: 34.7500)),
        CityLocation(name: "Herzliya", nameHebrew: "הרצליה", coordinate: CLLocationCoordinate2D(latitude: 32.1624, longitude: 34.8443)),
        CityLocation(name: "Kfar Saba", nameHebrew: "כפר סבא", coordinate: CLLocationCoordinate2D(latitude: 32.1769, longitude: 34.9072)),
        CityLocation(name: "Raanana", nameHebrew: "רעננה", coordinate: CLLocationCoordinate2D(latitude: 32.1847, longitude: 34.8708)),
        CityLocation(name: "Modi'in", nameHebrew: "מודיעין", coordinate: CLLocationCoordinate2D(latitude: 31.8969, longitude: 35.0106)),
        CityLocation(name: "Lod", nameHebrew: "לוד", coordinate: CLLocationCoordinate2D(latitude: 31.9514, longitude: 34.8883)),
        CityLocation(name: "Ramla", nameHebrew: "רמלה", coordinate: CLLocationCoordinate2D(latitude: 31.9296, longitude: 34.8667)),
        
        // North
        CityLocation(name: "Nazareth", nameHebrew: "נצרת", coordinate: CLLocationCoordinate2D(latitude: 32.7022, longitude: 35.2975)),
        CityLocation(name: "Acre", nameHebrew: "עכו", coordinate: CLLocationCoordinate2D(latitude: 32.9275, longitude: 35.0833)),
        CityLocation(name: "Tiberias", nameHebrew: "טבריה", coordinate: CLLocationCoordinate2D(latitude: 32.7950, longitude: 35.5325)),
        CityLocation(name: "Safed", nameHebrew: "צפת", coordinate: CLLocationCoordinate2D(latitude: 32.9650, longitude: 35.4950)),
        CityLocation(name: "Nahariya", nameHebrew: "נהריה", coordinate: CLLocationCoordinate2D(latitude: 33.0078, longitude: 35.0947)),
        CityLocation(name: "Karmiel", nameHebrew: "כרמיאל", coordinate: CLLocationCoordinate2D(latitude: 32.9186, longitude: 35.2969)),
        
        // South
        CityLocation(name: "Ashkelon", nameHebrew: "אשקלון", coordinate: CLLocationCoordinate2D(latitude: 31.6688, longitude: 34.5742)),
        CityLocation(name: "Eilat", nameHebrew: "אילת", coordinate: CLLocationCoordinate2D(latitude: 29.5577, longitude: 34.9519)),
        CityLocation(name: "Dimona", nameHebrew: "דימונה", coordinate: CLLocationCoordinate2D(latitude: 31.0686, longitude: 35.0328)),
        CityLocation(name: "Arad", nameHebrew: "ערד", coordinate: CLLocationCoordinate2D(latitude: 31.2587, longitude: 35.2130)),
        
        // Gush Dan (Greater Tel Aviv)
        CityLocation(name: "Givatayim", nameHebrew: "גבעתיים", coordinate: CLLocationCoordinate2D(latitude: 32.0700, longitude: 34.8117)),
        CityLocation(name: "Bnei Brak", nameHebrew: "בני ברק", coordinate: CLLocationCoordinate2D(latitude: 32.0808, longitude: 34.8339)),
        CityLocation(name: "Hod HaSharon", nameHebrew: "הוד השרון", coordinate: CLLocationCoordinate2D(latitude: 32.1500, longitude: 34.8889)),
        CityLocation(name: "Yehud", nameHebrew: "יהוד", coordinate: CLLocationCoordinate2D(latitude: 32.0333, longitude: 34.8833)),
    ]
    
    static func findByName(_ name: String) -> CityLocation? {
        all.first { $0.name == name || $0.nameHebrew == name }
    }
}
