//
//  AddEditSoundController.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 03.05.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import SBKit
import UIKit


public class AddEditSoundController: AddEditSoundControllerBase, UIDocumentPickerDelegate, AudioRecorderViewControllerDelegate{
    
    public var editableSound:SoundObject?
    lazy var inputTypesView     = UIStackView()
    lazy var openRecorderButton = UIButton(type: .system)
    lazy var openFileButton     = UIButton(type: .system)
    
    override public func setUpUI(){
        setUpAddImageButtonView()
        setUpNameInputView()
        if state == .Edit{
            guard let soundFileName = editableSound!.fileName else {
                return
            }
            setUpPlayerView(nameTextInput)
            newSoundReady(soundFileName)
            fillSoundData(editableSound!)
        }
        
        if state == .Add{
            setUpInputTypesView()
            setUpPlayerView(inputTypesView)
        }
    }
    
    @objc func onOpenFileButton(_ sender: UIButton){
        AudioPlayer.sharedInstance.stop()
        let importMenu = UIDocumentPickerViewController(documentTypes: ["public.audiovisual-content"], in: .open)
        importMenu.delegate = self
        self.present(importMenu, animated: true, completion: nil)
    }
    
    @objc func onOpenRecorderButton(_ sender: UIButton){
        AudioPlayer.sharedInstance.stop()
        let audioRecorderController = AudioRecorderController()
        audioRecorderController.audioRecorderDelegate = self
        self.navigationController!.pushViewController(audioRecorderController, animated: true)
    }
    
    func setUpInputTypesView(){
        guard editableSound == nil else {
            return
        }
        self.view.addSubview(inputTypesView)
        inputTypesView.axis             = NSLayoutConstraint.Axis.horizontal
        inputTypesView.distribution     = UIStackView.Distribution.fillEqually
        inputTypesView.alignment        = UIStackView.Alignment.center
        inputTypesView.spacing          = 16
        
        openRecorderButton.setTitle("Record Audio", for: .normal)
        openFileButton.setTitle("Pick Audio File", for: .normal)
        
        openRecorderButton.clipsToBounds = true
        openRecorderButton.layer.borderWidth = 0.5
        openRecorderButton.layer.cornerRadius    = (openRecorderButton.frame.size.width) / 2
        openRecorderButton.layer.borderColor = UIColor.lightGray.cgColor
        
        
        openRecorderButton.clipsToBounds = true
        openFileButton.layer.borderWidth = 0.5
        openFileButton.layer.borderColor = UIColor.lightGray.cgColor
        openFileButton.layer.cornerRadius    = (openFileButton.frame.size.width) / 2
        
        
        inputTypesView.addArrangedSubview(openRecorderButton)
        inputTypesView.addArrangedSubview(openFileButton)
        
        inputTypesView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.nameTextInput.snp.bottom).offset(32)
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        openRecorderButton.addTarget(self, action: #selector(onOpenRecorderButton), for: .touchUpInside)
        openFileButton.addTarget(self, action: #selector(onOpenFileButton), for: .touchUpInside)
    }
    
    func saveExistSound(_ newSoundName:String, _ newSoundImage:UIImage?, _ newSoundFileName:String){
        guard let existSound = editableSound else{
            return
        }
        existSound.name = newSoundName
        existSound.volume = VolumeManager.getVolumeValue(volumeSegmentControl.selectedSegmentIndex)
        if let image = newSoundImage{
            existSound.image = image.pngData()
        }
        existSound.fileName = newSoundFileName
        do {
            try moc.save()
            soundSaved = true
        } catch let error as NSError {
            print(error)
            moc.rollback()
        }
    }
    
    override public func saveSound(_ soundName:String, _ soundImage:UIImage?, _ soundFileName:String){
        if state == .Add{
            saveNewSound(soundName, soundImage, soundFileName)
        }else{
            saveExistSound(soundName, soundImage, soundFileName)
        }
        stopLoadingAnimation(completion: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        importURL(url)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }

    func audioRecorderFinished(_ newSoundFileName: String) {
         newSoundReady(newSoundFileName)
     }
    
    public func fillSoundData(_ sound:SoundObject){
        nameTextInput.text = sound.name
        if let soundImageData = sound.image{
            updateImage(image: UIImage(data: soundImageData))
        }
        volumeSegmentControl.selectedSegmentIndex = VolumeManager.getVolumeIndex(sound.volume)
    }
}
