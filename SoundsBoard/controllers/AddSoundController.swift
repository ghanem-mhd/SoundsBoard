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

class AddSoundController: UIViewController, AudioRecorderViewControllerDelegate, UIDocumentPickerDelegate, NVActivityIndicatorViewable, SoundsFilesMangerCopyDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AudioPlayerCustomDelegate{

    
    lazy var doneButton         = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonClicked))
    lazy var addImageButton     = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    lazy var nameTextInput      = UITextField()
    lazy var inputTypesView     = UIStackView()
    
    lazy var playButton         = UIButton()
    lazy var stopButton         = UIButton()
    lazy var pauseButton        = UIButton()
    lazy var openRecorderButton = UIButton(type: .system)
    lazy var openFileButton     = UIButton(type: .system)
    
    lazy var playerControllersView         = UIStackView()
    lazy var trimSlider       = MultiSlider()
    lazy var startTimeLabel   = UILabel()
    lazy var endTimeLabel     = UILabel()
    lazy var playBackDurationView = UILabel()
    lazy var trimmedDuration  = UILabel()
    lazy var hintLabel        = UILabel()
    
    var soundFileName: String?
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
        nameTextInput.placeholder = "Sound name"
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
            make.top.equalTo(self.nameTextInput.snp.bottom).offset(32)
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        openRecorderButton.addTarget(self, action: #selector(onOpenRecorderButton), for: .touchUpInside)
        openFileButton.addTarget(self, action: #selector(onOpenFileButton), for: .touchUpInside)
    }
    
    
    func setUpPlayerView(){

        trimSlider = MultiSlider()
        self.view.addSubview(trimSlider)
        trimSlider.inputView?.isUserInteractionEnabled = false
        trimSlider.orientation = .horizontal
        trimSlider.outerTrackColor = .red
        trimSlider.minimumValue = 0
        trimSlider.maximumValue = 100
        trimSlider.snapStepSize = 1
        trimSlider.isHapticSnap = true
        trimSlider.valueLabelPosition = .notAnAttribute
        trimSlider.tintColor = .systemBlue
        trimSlider.trackWidth = 8
        trimSlider.hasRoundTrackEnds = true
        trimSlider.thumbCount = 2
        
        self.view.addSubview(startTimeLabel)
        startTimeLabel.text = "00:00"
        startTimeLabel.font =  UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.light)
        startTimeLabel.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self.view.snp.left).offset(16)
            make.centerY.equalTo(self.trimSlider.snp.centerY)
        }
        
        self.view.addSubview(endTimeLabel)
        endTimeLabel.text = "00:00"
        endTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.light)
        endTimeLabel.snp.makeConstraints{ (make) -> Void in
            make.right.equalTo(self.view.snp.right).offset(-16)
            make.centerY.equalTo(self.trimSlider.snp.centerY)
        }
        
        trimSlider.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.inputTypesView.snp.bottom).offset(82)
            make.left.equalTo(startTimeLabel.snp.right).offset(8)
            make.right.equalTo(endTimeLabel.snp.left).offset(-8)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        trimSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged) // continuous changes
        trimSlider.addTarget(self, action: #selector(sliderDragEnded(_:)), for: . touchUpInside) // sent when drag ends
        
        self.view.addSubview(hintLabel)
        hintLabel.text = "Move the slider thumbs to trim the sound."
        hintLabel.textColor = .lightGray
        hintLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.light)
        hintLabel.textAlignment = .center
        hintLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.trimSlider.snp.bottom).offset(16)
            make.width.equalTo(self.view.snp.width)
        }
        
        self.view.addSubview(playBackDurationView)
        playBackDurationView.text = "00:00 - 04:58"
        playBackDurationView.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.light)
        playBackDurationView.textColor = .lightGray
        playBackDurationView.textAlignment = .center
        playBackDurationView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(hintLabel.snp.bottom).offset(16)
            make.width.equalTo(self.view.snp.width)
        }
        
        self.view.addSubview(playerControllersView)
                
        playerControllersView.axis             = NSLayoutConstraint.Axis.horizontal
        playerControllersView.distribution     = UIStackView.Distribution.equalCentering
        playerControllersView.alignment        = UIStackView.Alignment.center
        
        playerControllersView.addArrangedSubview(stopButton)
        playerControllersView.addArrangedSubview(playButton)
        playerControllersView.addArrangedSubview(pauseButton)
        
        playerControllersView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.inputTypesView.snp.bottom).offset(32)
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
        
        playerVisiblity(isHidden: false)
    }

     // MARK: - Player Controllers
    
    func playerVisiblity(isHidden:Bool){
        playerControllersView.isHidden = isHidden
        startTimeLabel.isHidden = isHidden
        endTimeLabel.isHidden = isHidden
        trimSlider.isHidden = isHidden
        hintLabel.isHidden = isHidden
        playBackDurationView.isHidden = isHidden
    }
    
    @objc func onPlayButtonClicked(_ sender: UIButton){
        if let soundFileName = soundFileName{
            let startTime = TimeInterval(exactly: trimSlider.value[0])
            let endTime = TimeInterval(exactly: trimSlider.value[1])
            AudioPlayer.sharedInstance.play(soundFileName: soundFileName, startTime: startTime, endTime: endTime, checkPlayed: true, customDelegate: self)
        }
    }
    
    @objc func onPauseButtonClicked(_ sender: UIButton){
        AudioPlayer.sharedInstance.pause()
    }
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        AudioPlayer.sharedInstance.stop()
    }
    
    @objc func sliderChanged(_ slider: MultiSlider){
        updateStartEndTrimmingViews(start: Float(slider.value[0]), end: Float(slider.value[1]))
    }
    
    @objc func sliderDragEnded(_ slider: MultiSlider){

    }
    
    func updateStartEndTrimmingViews(start:Float, end:Float){
        AudioPlayer.sharedInstance.stop()
        self.startTimeLabel.text = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: start)
        self.endTimeLabel.text = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: end)
        let newDuraiton = end - start
        self.newDurationString = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: newDuraiton)
        self.playBackDurationView.text = "00:00 - \(newDurationString)"
    }
    
    var newDurationString = ""
    
    func setUpTrimmer(_ soundFileName: String){
        let soundDuration:Int = Int(AudioPlayer.sharedInstance.getDuration(soundFileName: soundFileName))
        self.endTimeLabel.text = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: soundDuration)
        self.trimSlider.maximumValue = CGFloat(soundDuration)
        self.trimSlider.value = [0,CGFloat(soundDuration)]
        self.newDurationString = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: soundDuration)
        self.playBackDurationView.text = "00:00 - \(newDurationString)"
    }
    
    func currentTimePlayed(currentTime: TimeInterval) {
        let currentTimePlayedString = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: Int(currentTime))
        self.playBackDurationView.text = "\(currentTimePlayedString) - \(newDurationString)"
    }
    
    // MARK: - Audio Recorder
    
    @objc func onOpenRecorderButton(_ sender: UIButton){
        let audioRecorderController = AudioRecorderController()
        audioRecorderController.audioRecorderDelegate = self
        self.navigationController!.pushViewController(audioRecorderController, animated: true)
        
    }
    
    func audioRecorderFinished(_ soundFileName: String) {
        newSoundReady(soundFileName: soundFileName)
    }
    
    func newSoundReady(soundFileName: String){
        if let old = self.soundFileName{
            AudioPlayer.sharedInstance.stop()
            SoundsFilesManger.deleteSoundFile(old)
        }
        self.soundFileName = soundFileName
        playerVisiblity(isHidden: false)
        setUpTrimmer(soundFileName)
    }
    
     // MARK: - Audio Picker
    
    @objc func onOpenFileButton(_ sender: UIButton){
        let importMenu = UIDocumentPickerViewController(documentTypes: ["public.audiovisual-content"], in: .open)
        importMenu.delegate = self
        self.present(importMenu, animated: true, completion: nil)
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
    
    func copyDidFinish(_ soundsoundFileName: String) {
        stopAnimating()
        newSoundReady(soundFileName: soundsoundFileName)
    }
    
    func copyDidFaild(_ erorr: Error) {
        stopAnimating()
        AlertsManager.showCopyFaildAlert(self)
    }
    
    // MARK: - Saving & Closing
    
    @objc func doneButtonClicked(_ sender: Any){
        guard let name = nameTextInput.text, name.isNotEmpty else{
            print("Name is empty")
            return
        }
        guard let image = self.soundImage else{
            print("Image is empty")
            return
        }
        
        guard let soundFileName = self.soundFileName else{
            print("geneeratedName is empty")
            return
        }
        saveNewSound(soundName: name, soundImage: image, soundFileName: soundFileName)
        self.navigationController?.popViewController(animated: true)
    }
    
    var soundSaved = false
    
    func saveNewSound(soundName:String, soundImage:UIImage, soundFileName:String){
        if let soundEntity = NSEntityDescription.entity(forEntityName: "SoundObject", in: moc){
            let soundObject = NSManagedObject(entity: soundEntity, insertInto: moc)
            soundObject.setValue(soundName, forKeyPath: "name")
            soundObject.setValue(soundImage.pngData(), forKeyPath: "image")
            soundObject.setValue(soundFileName, forKeyPath: "soundFileName")
            do {
                try moc.save()
                soundSaved = true
            } catch let error as NSError {
                print(error)
                moc.rollback()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard !soundSaved else{
            return
        }
        if isMovingFromParent {
            if let soundGenratedName = soundFileName{
                AudioPlayer.sharedInstance.stop()
                SoundsFilesManger.deleteSoundFile(soundGenratedName)
            }
        }
    }
    
     // MARK: - Image Pickers
    
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
}
