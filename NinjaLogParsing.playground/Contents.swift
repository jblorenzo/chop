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

enum NinjaParameters : String {
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
}

extension Collection where Indices.Iterator.Element == Index {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

protocol ParametersVerifier {
    var logs : Logs { get set }

    func verifyParameters(parameters : ParsedParameters)
    func getReport() -> Logs
    func printReport()
    mutating func checkAdId(n: String, parameters: ParsedParameters, logs : Logs)
    mutating func checkEventtype(n: String, parameters: ParsedParameters, logs : Logs)
    mutating func checkViewType(n: String, parameters: ParsedParameters, logs : Logs)
}

extension ParametersVerifier where Self : NSObject {
    func printReport() {
        let report = getReport()
        for line in report {
            print(line)
        }
    }
}

class CommonParametersVerifier : NSObject, ParametersVerifier {
    internal var logs: Logs = Logs()

    var counts = [String:Int]()
    var required = [
        NinjaParameters.gaid.rawValue,
        NinjaParameters.long.rawValue,
        NinjaParameters.lat.rawValue,
        NinjaParameters.bR.rawValue,
        NinjaParameters.cC.rawValue,
        NinjaParameters.v.rawValue,
        NinjaParameters.v.rawValue,
        NinjaParameters.city_id.rawValue,
        NinjaParameters.region_id.rawValue,
        NinjaParameters.district_id.rawValue,
        NinjaParameters.business_region.rawValue
    ]
    
    internal func checkViewType(n: String, parameters: ParsedParameters, logs: Logs) {
        
    }

    internal func checkEventtype(n: String, parameters: ParsedParameters, logs: Logs) {
        
    }

    internal func checkAdId(n: String, parameters: ParsedParameters, logs: Logs) {
        
    }

    internal func getReport() -> Logs {
        for param in required {
            if let count = counts[param], count > 0 {
                
            } else {
                logs.append("Param [\(param)] is missing.")
            }
        }
        
        return logs
    }

    internal func verifyParameters(parameters: ParsedParameters) {
        for param in required {
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
        for v in verifiers {
            v.verifyParameters(parameters: parameters)
        }
    }
    
}

print("Report:")

for v in verifiers {
    v.printReport()
}
