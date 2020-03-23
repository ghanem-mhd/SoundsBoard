//
//  AddSoundController.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 08.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import ALCameraViewController
import SwiftySound
import CoreData


class AddSoundController: UIViewController, AudioRecorderViewControllerDelegate {
    
    lazy var doneButton         = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonClicked))
    lazy var addImageButton     = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    lazy var nameTextInput      = UITextField()
    lazy var inputTypesView     = UIStackView()
    lazy var playerView         = UIStackView()
    lazy var playButton         = UIButton()
    lazy var stopButton         = UIButton()
    lazy var pauseButton        = UIButton()
    lazy var openRecorderButton = UIButton(type: .system)
    lazy var openFileButton     = UIButton(type: .system)
    
    var generatedName: String?
    var soundImage:UIImage?
    var playedSound: Sound?
    var moc : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // getting appDelegate's reference
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        self.moc = appDelegate.persistentContainer.viewContext
        
        self.title = "Create new Sound"
        self.navigationItem.rightBarButtonItem = doneButton
        
        setUpAddImageButtonView()
        setUpNameInputView()
        setUpAudioPickerView()
        setUpPlayerView()
    }
    
    func setUpAddImageButtonView(){
        self.view.addSubview(addImageButton)
        let imageIcon = UIImage(named: "round_add_photo_alternate_black_48pt")
        addImageButton.setImage(imageIcon, for: .normal)
        addImageButton.contentMode = .center
        addImageButton.snp.makeConstraints{ (make) -> Void in
            make.width.height.equalTo(100)
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
        }
        addImageButton.clipsToBounds = true
        addImageButton.layer.borderWidth    = 0.5
        addImageButton.layer.cornerRadius   = (addImageButton.frame.size.width) / 2
        addImageButton.layer.borderColor    = UIColor.lightGray.cgColor
        addImageButton.addTarget(self, action: #selector(addImageButtonClicked(_:)), for: .touchUpInside)
    }
    
    func setUpNameInputView(){
        self.view.addSubview(nameTextInput)
        nameTextInput.placeholder = "Enter text here"
        nameTextInput.font = UIFont.systemFont(ofSize: 15)
        nameTextInput.borderStyle = UITextField.BorderStyle.roundedRect
        nameTextInput.autocorrectionType = UITextAutocorrectionType.no
        nameTextInput.keyboardType = UIKeyboardType.default
        nameTextInput.returnKeyType = UIReturnKeyType.done
        nameTextInput.clearButtonMode = UITextField.ViewMode.whileEditing
        nameTextInput.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        nameTextInput.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.addImageButton.snp.bottom).offset(16)
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.centerX.equalTo(self.view.snp.centerX)
        }
    }
    
    
    @objc func addImageButtonClicked(_ sender: UIButton){
        let cameraViewController = CameraViewController(croppingParameters: CroppingParameters(isEnabled: true, allowResizing: false), allowsLibraryAccess: true) { [weak self] image, asset in
            if let chosenImage = image {
                self?.soundImage = chosenImage
                self?.addImageButton.setImage(chosenImage, for: .normal)
            }
            self?.dismiss(animated: true, completion: nil)
        }
        present(cameraViewController, animated: true, completion: nil)
    }
    
    func setUpAudioPickerView(){
        
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
        inputTypesView.backgroundColor = .yellow
        
        inputTypesView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.nameTextInput.snp.bottom).offset(16)
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        openRecorderButton.addTarget(self, action: #selector(onOpenRecorderButton), for: .touchUpInside)
        openFileButton.addTarget(self, action: #selector(onOpenFileButton), for: .touchUpInside)
    }
    
    func setUpPlayerView(){
        
        self.view.addSubview(playerView)
        
        playerView.isHidden = true
        
        playerView.axis             = NSLayoutConstraint.Axis.horizontal
        playerView.distribution     = UIStackView.Distribution.equalCentering
        playerView.alignment        = UIStackView.Alignment.center
        
        playerView.addArrangedSubview(stopButton)
        playerView.addArrangedSubview(playButton)
        playerView.addArrangedSubview(pauseButton)
        
        playerView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.inputTypesView.snp.bottom).offset(24)
            make.width.equalTo(self.view.frame.width / 2)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        if let playIcon = UIImage(named:"round_play_arrow_black_48pt"){
            playButton.setImage(playIcon, for: .normal)
            playButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        if let pauseIcon = UIImage(named: "round_pause_black_48pt"){
            pauseButton.setImage(pauseIcon , for: .normal)
            pauseButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        if let stopIcon = UIImage(named: "round_stop_black_48pt"){
            stopButton.setImage(stopIcon , for: .normal)
            stopButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        playButton.addTarget(self, action: #selector(onPlayButtonClicked), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(onPauseButtonClicked), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(onStopButtonClicked), for: .touchUpInside)
    }
    
    @objc func onOpenRecorderButton(_ sender: UIButton){
        let audioRecorderController = AudioRecorderController()
        audioRecorderController.audioRecorderDelegate = self
        self.navigationController!.pushViewController(audioRecorderController, animated: true)
        
    }
    
    @objc func onOpenFileButton(_ sender: UIButton){
        
    }
    
    func audioRecorderFinished(_ generatedName: String) {
        self.generatedName = generatedName
        playerView.isHidden = false
    }
    
    @objc func onPlayButtonClicked(_ sender: UIButton){
        if let generatedName = generatedName{
            if playedSound == nil{
                playedSound = Sound.init(url: SoundsFilesManger.getSoundURL(generatedName))
                playedSound?.play()
            }else{
                if playedSound?.paused ?? false{
                    playedSound?.resume()
                }else{
                    if !(playedSound?.playing ?? true){
                        playedSound?.play()
                    }
                }
            }
        }
    }
    
    @objc func onPauseButtonClicked(_ sender: UIButton){
        playedSound?.pause()
    }
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        playedSound?.stop()
        playedSound = nil
    }
    
    
    @objc func doneButtonClicked(_ sender: Any){
        guard let name = nameTextInput.text, name.isNotEmpty else{
            print("Name is empty")
            return
        }
        guard let image = self.soundImage else{
            print("Image is empty")
            return
        }
        
        guard let generatedName = self.generatedName else{
            print("geneeratedName is empty")
            return
        }
        saveNewSound(soundName: name, soundImage: image, generatedName: generatedName)
        self.navigationController?.popViewController(animated: true)
    }
    
    func saveNewSound(soundName:String, soundImage:UIImage, generatedName:String){
        if let soundEntity = NSEntityDescription.entity(forEntityName: "SoundObject", in: moc){
            let soundObject = NSManagedObject(entity: soundEntity, insertInto: moc)
            soundObject.setValue(soundName, forKeyPath: "name")
            soundObject.setValue(soundImage.pngData(), forKeyPath: "image")
            soundObject.setValue(generatedName, forKeyPath: "generatedName")
            do {
                try moc.save()
            } catch let error as NSError {
                print(error)
                moc.rollback()
            }
        }
    }
}
