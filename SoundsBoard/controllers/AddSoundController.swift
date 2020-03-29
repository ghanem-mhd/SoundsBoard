//
//  AddSoundController.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 08.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import SwiftySound
import CoreData
import MobileCoreServices
import NVActivityIndicatorView
import MultiSlider

class AddSoundController: UIViewController, AudioRecorderViewControllerDelegate, UIDocumentPickerDelegate, NVActivityIndicatorViewable, SoundsFilesMangerCopyDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
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
    lazy var playerSlider       = MultiSlider()
    lazy var currentTimeLabel   = UILabel()
    lazy var durationLabel      = UILabel()
    
    var generatedName: String?
    var soundImage:UIImage?
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
        let alert = UIAlertController(title:nil, message:nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default , handler:{ (UIAlertAction)in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default , handler:{ (UIAlertAction)in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func openCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func openGallary(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        self.soundImage = image
        self.addImageButton.setImage(image, for: .normal)
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
        
        
    
       
       

        
    
        playerSlider = MultiSlider()
        self.view.addSubview(playerSlider)
        playerSlider.orientation = .horizontal
        playerSlider.minimumValue = 0
        playerSlider.maximumValue = 1
        playerSlider.outerTrackColor = .gray
        playerSlider.valueLabelPosition = .top
        playerSlider.tintColor = .systemBlue
        playerSlider.trackWidth = 16
        playerSlider.thumbCount = 1
        playerSlider.value = [0]
        playerSlider.valueLabels[0].isHidden = true
        playerSlider.disabledThumbIndices = [0]
        playerSlider.hasRoundTrackEnds = true

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let randomNumber = Int.random(in: 0...100)
            print("Number: \(randomNumber)")
            let currentTime = AudioPlayer.sharedInstance.getCurrentTime()
            let duration = AudioPlayer.sharedInstance.getDuration()
            if currentTime != 0 || duration != 0{
                self.playerSlider.value = [CGFloat(currentTime/duration)]
                var minutes = duration/60
                var seconds = duration - minutes * 60
                self.durationLabel.text = String(format: "%02d:%02d", minutes,seconds)
                
            
                minutes = currentTime/60
                seconds = currentTime - minutes * 60
                self.currentTimeLabel.text = String(format: "%02d:%02d", minutes,seconds)
            }
        }
        
        self.view.addSubview(currentTimeLabel)
        currentTimeLabel.text = "00:01"
        currentTimeLabel.font = currentTimeLabel.font.withSize(16)

        currentTimeLabel.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self.view.snp.left).offset(16)
            make.centerY.equalTo(self.playerSlider.snp.centerY)
        }

        
        self.view.addSubview(durationLabel)
        durationLabel.text = "00:06"
        durationLabel.font = durationLabel.font.withSize(16)

        durationLabel.snp.makeConstraints{ (make) -> Void in
            make.right.equalTo(self.view.snp.right).offset(-16)
            make.centerY.equalTo(self.playerSlider.snp.centerY)
        }
        
        
        playerSlider.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.playerView.snp.bottom).offset(24)
            make.left.equalTo(currentTimeLabel.snp.right).offset(16)
            make.right.equalTo(durationLabel.snp.left).offset(-16)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        playerSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged) // continuous changes
        playerSlider.addTarget(self, action: #selector(sliderDragEnded(_:)), for: . touchUpInside) // sent when drag ends
        


        
    }
    
    @objc func sliderChanged(_ slider: MultiSlider){

        
    }
    
    @objc func sliderDragEnded(_ slider: MultiSlider){

        
    }
    
    @objc func onOpenRecorderButton(_ sender: UIButton){
        let audioRecorderController = AudioRecorderController()
        audioRecorderController.audioRecorderDelegate = self
        self.navigationController!.pushViewController(audioRecorderController, animated: true)
        
    }
    
    @objc func onOpenFileButton(_ sender: UIButton){
        let importMenu = UIDocumentPickerViewController(documentTypes: ["public.audiovisual-content"], in: .open)
        importMenu.delegate = self
        self.present(importMenu, animated: true, completion: nil)
    }
    
    func audioRecorderFinished(_ generatedName: String) {
        if let old = self.generatedName{
            AudioPlayer.sharedInstance.stop()
            SoundsFilesManger.deleteSoundFile(old)
        }
        self.generatedName = generatedName
        playerView.isHidden = false
    }
    
    @objc func onPlayButtonClicked(_ sender: UIButton){
        if let generatedName = generatedName{
            AudioPlayer.sharedInstance.play(url: SoundsFilesManger.getSoundURL(generatedName), checkPlayed: true)
        }
    }
    
    @objc func onPauseButtonClicked(_ sender: UIButton){
        AudioPlayer.sharedInstance.pause()
    }
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        AudioPlayer.sharedInstance.stop()
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
    
    var soundSaved = false
    
    func saveNewSound(soundName:String, soundImage:UIImage, generatedName:String){
        if let soundEntity = NSEntityDescription.entity(forEntityName: "SoundObject", in: moc){
            let soundObject = NSManagedObject(entity: soundEntity, insertInto: moc)
            soundObject.setValue(soundName, forKeyPath: "name")
            soundObject.setValue(soundImage.pngData(), forKeyPath: "image")
            soundObject.setValue(generatedName, forKeyPath: "generatedName")
            do {
                try moc.save()
                soundSaved = true
            } catch let error as NSError {
                print(error)
                moc.rollback()
            }
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let fileType = SoundsFilesManger.checkFileType(url)
        if fileType == SupportedFileTypes.unknowen{
            AlertsManager.showFileNotSuportedAlert(self)
            return
        }
        SoundsFilesManger.copyFile(url, self)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func copyDidStart() {
        startAnimating()
    }
    
    func copyDidFinish(_ soundGeneratedName: String) {
        stopAnimating()
        if let old = self.generatedName{
            AudioPlayer.sharedInstance.stop()
            SoundsFilesManger.deleteSoundFile(old)
        }
        self.generatedName = soundGeneratedName
        playerView.isHidden = false
    }
    
    func copyDidFaild(_ erorr: Error) {
        stopAnimating()
        AlertsManager.showCopyFaildAlert(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard !soundSaved else{
            return
        }
        if isMovingFromParent {
            if let soundGenratedName = generatedName{
                AudioPlayer.sharedInstance.stop()
                SoundsFilesManger.deleteSoundFile(soundGenratedName)
            }
        }
    }
}
