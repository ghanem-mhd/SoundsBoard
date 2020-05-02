//
//  ShareViewController.swift
//  SBShare
//
//  Created by Mohammed Ghannm on 01.05.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import SBKit
import SnapKit
import CoreData
import AVKit

class ShareViewController: UIViewController {

    let alert = UIAlertController(title: nil, message: "Saving...", preferredStyle: .alert)
    lazy var hint           = UILabel()
    lazy var nameTextInput  = UITextField()
    var moc : NSManagedObjectContext!
    
    override func viewDidLoad() {
        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        setupUI()
    }

    func setupUI(){
        self.view.addSubview(nameTextInput)
        nameTextInput.placeholder = "Sound name"
        nameTextInput.font = UIFont.systemFont(ofSize: 15)
        nameTextInput.borderStyle = UITextField.BorderStyle.roundedRect
        nameTextInput.clearButtonMode = UITextField.ViewMode.whileEditing
        nameTextInput.delegate = self
        nameTextInput.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        nameTextInput.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        self.view.addSubview(hint)
        hint.text = "Choose a name for this new sound. Later inside the app you can edit/trim the sound."
        hint.textColor = .lightGray
        hint.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.light)
        hint.numberOfLines = 3
        hint.textAlignment = .center
        hint.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.nameTextInput.snp.bottom).offset(16)
            make.width.equalTo(self.view.snp.width).offset(-16)
            make.centerX.equalTo(self.view.snp.centerX)
        }
    }
    
    func save(){
        guard let context = extensionContext else{
            return
        }
        for item in context.inputItems as! [NSExtensionItem] {
            guard let attachments = item.attachments else { continue }
            for itemProvider in attachments {
                itemProvider.loadItem(forTypeIdentifier: String(kUTTypeQuickTimeMovie), options: nil, completionHandler: { (data, error) in
                    if let url = data as? URL{
                        SoundsFilesManger.copyURLFromShareExtension(url, self)
                    }
                })
            }
        }
    }
    
    func saveNewSound(_ soundName:String, _ soundFileName:String){
        if let soundEntity = NSEntityDescription.entity(forEntityName: "SoundObject", in: moc){
            let soundObject = NSManagedObject(entity: soundEntity, insertInto: moc)
            soundObject.setValue(soundName, forKeyPath: "name")
            soundObject.setValue(false, forKeyPath: "isSound")
            soundObject.setValue(soundFileName, forKeyPath: "fileName")
            do {
                try moc.save()
                self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
            } catch let error as NSError {
                print(error)
                moc.rollback()
            }
        }
    }
    
    @IBAction func onCancelButtonClicked(_ sender: Any) {
        if let context = extensionContext{
            context.cancelRequest(withError: NSError(domain: "com.domain.name", code: 0, userInfo: nil))
        }
    }
    
    @IBAction func onSaveButtonClicked(_ sender: Any) {
        save()
    }
    
    
    func test(){
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
}


extension ShareViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension ShareViewController: SoundsFilesMangerShareDelegate{
    func copyDidFinish(_ fileName:String) {
        guard let name = nameTextInput.text else{
            return
        }
        saveNewSound(name, fileName)
    }
    func copyDidFailed(_ error: Error) {
        
    }
}
