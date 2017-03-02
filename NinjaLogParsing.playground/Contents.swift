#!/usr/bin/swift
// Ninja Log Parser
// Swift 3.0
// John Bennedict Lorenzo
//
// Usage:
// $ chmod +x NinjaLogParsing.playground/Contents.swift
// $ ./NinjaLogParsing.playground/Contents.swift <relative log path>

import Foundation

typealias ParsedParameters = [String : String]
typealias Logs = [String]

enum NinjaParameter : String {
    case user_id
    case business_region
    case lat
    case long
    case bR
    case rE
    case cC
    case region_id
    case city_id
    case district_id
    case category_level1_id
    case category_level2_id
    case category_level3_id
    case category_level4_id
    case resultset_type
    case result_set_format
    case search_string
    case sort_by
    case page_number
    case total_pages
    case result_count
    case impressions
    case item_id
    case images_count
    case channel
    case push_id
    case push_enb
    case silent
    case gaid
    case v
    case dt
    case ninjaver
    
    case ts
    case platform_type
    case language
    case user_type
    case region_name
    case city_name
    case district_name
    
    case first_app_launch
    case first_app_launch_date
    case installed_packages
    case app_open_source
    case facebook_id
    case origin
    
    case login_method
    
    case eventName
}

enum NinjaEvent : String {
    case app_install
    case app_open
    
    case map_location_select
    case map_location_complete
    
    case item_select
}

extension Collection where Indices.Iterator.Element == Index {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

protocol ParametersVerifier {
    var logs : Logs { get set }
    
    //    var counts : [String:Int] { get set}
    //    var required : [String] { get set }
    
    func getReport() -> Logs
    func printReport()
    
    mutating func verifyParameters(parameters : ParsedParameters)
//    mutating func checkAdId(n: String, parameters: ParsedParameters, logs : Logs)
//    mutating func checkEventtype(n: String, parameters: ParsedParameters, logs : Logs)
//    mutating func checkViewType(n: String, parameters: ParsedParameters, logs : Logs)
}

extension ParametersVerifier where Self : NSObject {
    func printReport() {
        let report = getReport()
        for line in report {
            print(line)
        }
    }
}

class InstallFlowVerifier : NSObject, ParametersVerifier {
    internal var logs: Logs = Logs()
    
    var eventCount = [String:Int]()
    var requiredEvents = [
        NinjaEvent.app_install,
        NinjaEvent.app_open,
    ]
    
    internal func getReport() -> Logs {
        for event in requiredEvents.map({ $0.rawValue }) {
            if let count = eventCount[event], count > 0 {
                
            } else {
                logs.append("Event [\(event)] is missing.")
            }
        }
        
        return logs
    }
    
    // Default verification method counts all the required objects
    func verifyParameters(parameters: ParsedParameters) {
        for event in requiredEvents.map({ $0.rawValue }) {
            if let eventName = parameters[NinjaParameter.eventName.rawValue]
                , eventName == event
            {
                if let count = eventCount[event] {
                    eventCount[event] = count + 1
                } else {
                    eventCount[event] = 1
                }
            }
        }
    }
}

class CommonParametersVerifier : NSObject, ParametersVerifier {
    internal var logs: Logs = Logs()
    
    var counts = [String:Int]()
    var required = [
        NinjaParameter.gaid,
        NinjaParameter.long,
        NinjaParameter.lat,
        NinjaParameter.bR,
        NinjaParameter.ts,
        NinjaParameter.cC,
        NinjaParameter.v,
        NinjaParameter.city_id,
        NinjaParameter.region_id,
        NinjaParameter.district_id,
        NinjaParameter.business_region
    ]
    
    internal func getReport() -> Logs {
        for param in required.map({ $0.rawValue }) {
            if let count = counts[param], count > 0 {
                
            } else {
                logs.append("Param [\(param)] is missing.")
            }
        }
        
        return logs
    }
    
    // Default verification method counts all the required objects
    func verifyParameters(parameters: ParsedParameters) {
        for param in required.map({ $0.rawValue }) {
            if let val = parameters[param]
                , val.characters.count > 0 {
                if let count = counts[param] {
                    counts[param] = count + 1
                } else {
                    counts[param] = 1
                }
            }
        }
    }
}

class LogParser {
    static let HYDRA_TRACKING_PREFIX = "HYDRA:: Tracking "
    
    static func isNinjaLine(s: String) -> Bool {
        if s.contains(LogParser.HYDRA_TRACKING_PREFIX) {
            return true
        }
        
        return false
    }
    
    static func parametersFor(s : String) -> [String : String] {
        var parameters = [String : String]()
        
        if let rangeOfPrefix = s.range(of: LogParser.HYDRA_TRACKING_PREFIX) {
            var trackingLog = s.substring(from: rangeOfPrefix.upperBound)
            trackingLog = trackingLog.substring(from: trackingLog.index(after: trackingLog.startIndex))
            trackingLog = trackingLog.substring(to: trackingLog.index(before: trackingLog.endIndex))
            let components = trackingLog.components(separatedBy: "&")
            for component in components {
                let keyval = component.components(separatedBy: "=")
                if let key = keyval[safe: 0],
                    let value = keyval[safe: 1] {
                    parameters[key] = value
                }
            }
            
            return parameters
        }
        
        return parameters
    }
}

// MARK: Main

func loadVerifiers() -> [ParametersVerifier] {
    var v = [ParametersVerifier]()
    
    v.append(CommonParametersVerifier())
    v.append(InstallFlowVerifier())
//    v.append(LocationFlowVerifier())
//    v.append(RegisterLoginFlowVerifier())
//    v.append(ReplyFlowVerifier())
    
    return v
}

var inputFile = "panamera"
var fileContents = ""
var verifiers : [ParametersVerifier] = loadVerifiers()

// Command line scripting
if let file = CommandLine.arguments[safe: 1] {
    let fileManager = FileManager.default
    
    inputFile = file
    
    if let contentData = FileManager.default.contents(atPath: fileManager.currentDirectoryPath.appending("/\(file)"))
        , let content = String(data: contentData, encoding: .utf8) {
        fileContents = content
    }
} else {
    guard let filePath = Bundle.main.path(forResource: inputFile, ofType: "log"),
        let contentData = FileManager.default.contents(atPath: filePath),
        let content = String(data: contentData, encoding: .utf8) else {
            
            print("Error: failed to read logs")
            exit(-1)
    }
    
    fileContents = content
}

let lines = fileContents.components(separatedBy: "\n")
for line in lines {
    if LogParser.isNinjaLine(s: line) {
        let parameters = LogParser.parametersFor(s: line)
        for var v in verifiers {
            v.verifyParameters(parameters: parameters)
        }
    }
}

for v in verifiers {
    print("Report for \(type(of: v)):")
    v.printReport()
}
