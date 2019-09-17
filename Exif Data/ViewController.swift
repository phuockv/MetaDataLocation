//
//  ViewController.swift
//  Exif Data
//
//  Created by Vuong Toan Chung on 8/20/19.
//  Copyright © 2019 Vuong Toan Chung. All rights reserved.
//

import UIKit
import AssetsLibrary
import Photos
import ImageIO
import MobileCoreServices
import AssetsLibrary
import CoreLocation



class ViewController: UIViewController {
	
	var locationManager: CLLocationManager?

	override func viewDidLoad() {
		super.viewDidLoad()
		let image  = UIImage.init(named: "ppppp")
		
		
		
		
		locationManager = CLLocationManager()
		//locationManager.delegate = self as! CLLocationManagerDelegate
		locationManager?.requestAlwaysAuthorization()
		
		view.backgroundColor = .gray
		
//demo(beach: image!)
		
		
		
		//Do any additional setup after loading the view, typically from a nib.
	}
	
	@IBAction func actionPicker() {
		
		let vc = UIImagePickerController()
		vc.sourceType = .camera
		vc.allowsEditing = true
		vc.delegate = self
		present(vc, animated: true)
		
	}
	
	func demo(beach: UIImage) {
		
		let imageData: Data = beach.jpegData(compressionQuality:1.0)!
		
		let cgImgSource: CGImageSource = CGImageSourceCreateWithData(imageData as CFData, nil)!
		let uti: CFString = CGImageSourceGetType(cgImgSource)!
		let dataWithEXIF: NSMutableData = NSMutableData(data: imageData)
		let destination: CGImageDestination = CGImageDestinationCreateWithData((dataWithEXIF as CFMutableData), uti, 1, nil)!
		
		
		let imageProperties = CGImageSourceCopyPropertiesAtIndex(cgImgSource, 0, nil)! as NSDictionary
		let mutable: NSMutableDictionary = imageProperties.mutableCopy() as! NSMutableDictionary
		
		let EXIFDictionary: NSMutableDictionary = (mutable[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary)!
		
		print("before modification \(EXIFDictionary)")
		
		EXIFDictionary[kCGImagePropertyExifUserComment as String] = "type:video  ppp"
		
		if #available(iOS 11.3, *) {
			EXIFDictionary[kCGImagePropertyIPTCExtLocationGPSLatitude as String] = "10° 47' 57.87"
		} else {
			// Fallback on earlier versions
		}
		
		mutable[kCGImagePropertyExifDictionary as String] = EXIFDictionary
		
		CGImageDestinationAddImageFromSource(destination, cgImgSource, 0, (mutable as CFDictionary))
		CGImageDestinationFinalize(destination)
		
		let testImage: CIImage = CIImage(data: dataWithEXIF as Data, options: nil)!
		let newproperties: NSDictionary = testImage.properties as NSDictionary
		
		print("after modification \(newproperties)")
	}
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		
	    let meta = info[UIImagePickerController.InfoKey.mediaMetadata]
		
		print(meta)
		
		let image = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
	
		
		if let imageData = image.jpegData(compressionQuality: 1.0), let metadata = locationManager!.location?.exifMetadata() {
			if let newImageData = addImageProperties(imageData: imageData, properties: metadata) {
				// newImageData now contains exif metadata
				
				
			}
		}
		
		
		dismiss(animated: true, completion:nil) // hide picker when done w/it.
	}
	
	func addImagePropertiesExif(imageData: Data, properties: NSMutableDictionary) -> Data? {
		let dict = NSMutableDictionary()
		dict[(kCGImagePropertyExifDictionary as String)] = properties
		
		if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
			if let uti = CGImageSourceGetType(source) {
				let destinationData = NSMutableData()
				if let destination = CGImageDestinationCreateWithData(destinationData, uti, 1, nil) {
					CGImageDestinationAddImageFromSource(destination, source, 0, dict as CFDictionary)
					if CGImageDestinationFinalize(destination) == false {
						return nil
					}
					return destinationData as Data
				}
			}
		}
		return nil
	}
	
	func addImageProperties(imageData: Data, properties: NSMutableDictionary) -> Data? {
		let dict = NSMutableDictionary()
		dict[(kCGImagePropertyGPSDictionary as String)] = properties
		
		if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
			if let uti = CGImageSourceGetType(source) {
				let destinationData = NSMutableData()
				if let destination = CGImageDestinationCreateWithData(destinationData, uti, 1, nil) {
					CGImageDestinationAddImageFromSource(destination, source, 0, dict as CFDictionary)
					if CGImageDestinationFinalize(destination) == false {
						return nil
					}
					return destinationData as Data
				}
			}
		}
		return nil
	}
	
	@objc func cameraImageSavedAsynchronously() {
		
	}
	
	func fetchLastImage(completion: (_ localIdentifier: String?) -> Void)
	{
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		fetchOptions.fetchLimit = 1
		
		let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
		if (fetchResult.firstObject != nil)
		{
			let lastImageAsset: PHAsset = fetchResult.firstObject as! PHAsset
			completion(lastImageAsset.localIdentifier)
		}
		else
		{
			completion(nil)
		}
	}
	
	func getDocumentsDirectory() -> String {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		print(paths)
		return (paths.first?.path)!
	}
	
	func saveImage(withMetadata image: UIImage, metadata: NSDictionary) {
		
		guard let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
			return
		}
		
		let filePath = "\(documentPath)/image1.jpg"
		
		guard let jpgData = image.jpegData(compressionQuality: 0.5) else { return }
		
		// Add metadata to jpgData
		guard let source = CGImageSourceCreateWithData(jpgData as CFData, nil),
			let uniformTypeIdentifier = CGImageSourceGetType(source) else { return }
		let finalData = NSMutableData(data: jpgData)
		guard let destination = CGImageDestinationCreateWithData(finalData, uniformTypeIdentifier, 1, nil) else { return }
		CGImageDestinationAddImageFromSource(destination, source, 0, metadata)
		guard CGImageDestinationFinalize(destination) else { return }
		
	
		print(filePath)
		
		
		finalData.write(toFile: filePath, atomically: true)
	}
}

extension CLLocation {
	
	func exifMetadata(heading: CLHeading? = nil) -> NSMutableDictionary {
		
		let GPSMetadata = NSMutableDictionary()
		let altitudeRef = Int(self.altitude < 0.0 ? 1 : 0)
		let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
		let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"
		
		// GPS metadata
		GPSMetadata[(kCGImagePropertyGPSLatitude as String)] = abs(self.coordinate.latitude)
		GPSMetadata[(kCGImagePropertyGPSLongitude as String)] = abs(self.coordinate.longitude)
		GPSMetadata[(kCGImagePropertyGPSLatitudeRef as String)] = latitudeRef
		GPSMetadata[(kCGImagePropertyGPSLongitudeRef as String)] = longitudeRef
		GPSMetadata[(kCGImagePropertyGPSAltitude as String)] = Int(abs(self.altitude))
		GPSMetadata[(kCGImagePropertyGPSAltitudeRef as String)] = altitudeRef
		GPSMetadata[(kCGImagePropertyGPSTimeStamp as String)] = self.timestamp.isoTime()
		GPSMetadata[(kCGImagePropertyGPSDateStamp as String)] = self.timestamp.isoDate()
		GPSMetadata[(kCGImagePropertyGPSVersion as String)] = "2.2.0.0"
		
		if let heading = heading {
			GPSMetadata[(kCGImagePropertyGPSImgDirection as String)] = heading.trueHeading
			GPSMetadata[(kCGImagePropertyGPSImgDirectionRef as String)] = "T"
		}
		
		return GPSMetadata
	}
}

extension Date {
	
	func isoDate() -> String {
		let f = DateFormatter()
		f.timeZone = TimeZone(abbreviation: "UTC")
		f.dateFormat = "yyyy:MM:dd"
		return f.string(from: self)
	}
	
	func isoTime() -> String {
		let f = DateFormatter()
		f.timeZone = TimeZone(abbreviation: "UTC")
		f.dateFormat = "HH:mm:ss.SSSSSS"
		return f.string(from: self)
	}
}















