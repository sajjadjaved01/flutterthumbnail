import Flutter
import UIKit
import AVFoundation
#if canImport(WebP)
import WebP
#endif

public class FlutterthumbnailPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutterthumbnail", binaryMessenger: registrar.messenger())
        let instance = FlutterthumbnailPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["video"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", 
                              message: "Missing video path", 
                              details: nil))
            return
        }
        
        let headers = args["headers"] as? [String: String]
        let format = args["format"] as? Int ?? 0
        let maxHeight = args["maxh"] as? Int ?? 0
        let maxWidth = args["maxw"] as? Int ?? 0
        let timeMs = args["timeMs"] as? Int ?? 0
        let quality = args["quality"] as? Int ?? 10
        
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "data":
            generateThumbnail(from: videoPath,
                            headers: headers,
                            format: format,
                            maxHeight: maxHeight,
                            maxWidth: maxWidth,
                            timeMs: timeMs,
                            quality: quality) { data, error in
                if let error = error {
                    result(FlutterError(code: "THUMBNAIL_ERROR", 
                                      message: error.localizedDescription, 
                                      details: nil))
                } else {
                    result(data)
                }
            }
            
        case "file":
            let outputPath = args["path"] as? String
            generateThumbnailFile(from: videoPath,
                                to: outputPath,
                                headers: headers,
                                format: format,
                                maxHeight: maxHeight,
                                maxWidth: maxWidth,
                                timeMs: timeMs,
                                quality: quality) { path, error in
                if let error = error {
                    result(FlutterError(code: "THUMBNAIL_ERROR", 
                                      message: error.localizedDescription, 
                                      details: nil))
                } else {
                    result(path)
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
private func generateThumbnail(from videoPath: String,
                             headers: [String: String]?,
                             format: Int,
                             maxHeight: Int,
                             maxWidth: Int,
                             timeMs: Int,
                             quality: Int,
                             completion: @escaping (Data?, Error?) -> Void) {
    let url = videoPath.hasPrefix("file://") ? URL(fileURLWithPath: String(videoPath.dropFirst(7))) :
             videoPath.hasPrefix("/") ? URL(fileURLWithPath: videoPath) :
             URL(string: videoPath)!
    
    let asset = AVURLAsset(url: url, options: headers.map { ["AVURLAssetHTTPHeaderFieldsKey": $0] })
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: maxWidth, height: maxHeight)
    
    let processImage: (CGImage) -> Void = { cgImage in
        let uiImage = UIImage(cgImage: cgImage)
        switch format {
        case 0: // JPEG
            let data = uiImage.jpegData(compressionQuality: CGFloat(quality) / 100.0)
            completion(data, nil)
        case 1: // PNG
            let data = uiImage.pngData()
            completion(data, nil)
        case 2: // WebP
            #if canImport(WebP)
            completion(nil, NSError(domain: "FlutterThumbnail", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "WebP format not implemented"]))
            #else
            completion(nil, NSError(domain: "FlutterThumbnail", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "WebP format not supported"]))
            #endif
        default:
            completion(nil, NSError(domain: "FlutterThumbnail", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Unsupported format"]))
        }
    }
    
    let time = CMTime(value: CMTimeValue(timeMs), timescale: 1000)
    
    if #available(iOS 16.0, *) {
        generator.generateCGImageAsynchronously(for: time) { image, _, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let image = image else {
                completion(nil, NSError(domain: "FlutterThumbnail", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"]))
                return
            }
            processImage(image)
        }
    } else {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = try generator.copyCGImage(at: time, actualTime: nil)
                DispatchQueue.main.async {
                    processImage(image)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
}
    
    private func generateThumbnailFile(from videoPath: String,
                                     to outputPath: String?,
                                     headers: [String: String]?,
                                     format: Int,
                                     maxHeight: Int,
                                     maxWidth: Int,
                                     timeMs: Int,
                                     quality: Int,
                                     completion: @escaping (String?, Error?) -> Void) {
        generateThumbnail(from: videoPath,
                         headers: headers,
                         format: format,
                         maxHeight: maxHeight,
                         maxWidth: maxWidth,
                         timeMs: timeMs,
                         quality: quality) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "FlutterThumbnail", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data generated"]))
                return
            }
            
            let ext = format == 0 ? "jpg" : format == 1 ? "png" : "webp"
            let fileName = outputPath ?? "\(UUID().uuidString).\(ext)"
            let fileURL = URL(fileURLWithPath: fileName)
            
            do {
                try data.write(to: fileURL)
                completion(fileURL.path, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}