import UIKit
import Flutter
import ContactsUI

@UIApplicationMain
class AppDelegate: FlutterAppDelegate, CNContactPickerDelegate {
  var pendingResult: FlutterResult?
  var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "app.contacts", binaryMessenger: controller.binaryMessenger)
    methodChannel?.setMethodCallHandler({ [weak self] call, result in
      guard let self = self else { return }
      if call.method == "pick" {
        self.pendingResult = result
        let picker = CNContactPickerViewController()
        picker.delegate = self
        controller.present(picker, animated: true, completion: nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
    let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
    pendingResult?(["name": name, "phone": phone])
    pendingResult = nil
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    pendingResult?(FlutterError(code: "canceled", message: "No contact chosen", details: nil))
    pendingResult = nil
  }
}
