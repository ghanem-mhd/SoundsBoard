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
import WARangeSlider
import Intents
import IntentsUI
import AVFoundation

open class AddEditSoundControllerBase: UIViewController, UINavigationControllerDelegate{
    
    public enum ControllerState{
        case Add
        case Edit
        case ShareExtension
    }
    
    public var externalAudioURL:URL?
    public var state:ControllerState = .ShareExtension
    public var moc : NSManagedObjectContext!
    public var soundSaved = false
    
    var currentSoundFileName: String?
    var currentSoundImage: UIImage?
    
    var isLoading = false
    var isPlaying = false
    var newDurationString = ""
    var loadingAlert = AlertsManager.getActivityIndicatorAlert()
    var temporalFileURL: URL?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        
        self.title = "Create new Sound"
        self.view.backgroundColor = .white
        self.navigationItem.rightBarButtonItem = saveButton
        
        setUpUI()
    }
    
    open func setUpUI(){
        setUpAddImageButtonView()
        setUpNameInputView()
        setUpPlayerView(nameTextInput)
        setUpVolumeSettingsControl()
      
        
        if state == .ShareExtension{
            self.navigationItem.leftBarButtonItem = cancelButton
            getSharedURL()
        }else{
            setUpSiriShortcutButton()
        }
    }
    
    public func setUpAddImageButtonView(){
        self.view.addSubview(addImageButton)
        let imageIcon = UIImage(named: "round_add_photo_alternate_black_48pt")
        addImageButton.setImage(imageIcon, for: .normal)
        addImageButton.contentMode = .scaleAspectFit
        addImageButton.snp.makeConstraints{ (make) -> Void in
            make.width.height.equalTo(100)
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
        }
        addImageButton.clipsToBounds = true
        addImageButton.layer.borderWidth    = 0.5
        addImageButton.layer.cornerRadius   = 10
        addImageButton.layer.borderColor    = UIColor.lightGray.cgColor
        addImageButton.addTarget(self, action: #selector(addImageButtonClicked(_:)), for: .touchUpInside)
    }
    
    public func setUpNameInputView(){
        self.view.addSubview(nameTextInput)
        nameTextInput.placeholder = "Sound name"
        nameTextInput.font = UIFont.systemFont(ofSize: 15)
        nameTextInput.borderStyle = UITextField.BorderStyle.roundedRect
        nameTextInput.delegate = self
        nameTextInput.clearButtonMode = UITextField.ViewMode.whileEditing
        nameTextInput.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        nameTextInput.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.addImageButton.snp.bottom).offset(16)
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.centerX.equalTo(self.view.snp.centerX)
        }
    }
    
    public func setUpPlayerView(_ upperView: UIView){
        
        self.view.addSubview(playerControllersView)
        
        playerControllersView.axis             = NSLayoutConstraint.Axis.horizontal
        playerControllersView.distribution     = UIStackView.Distribution.equalCentering
        playerControllersView.alignment        = UIStackView.Alignment.center
        
        playerControllersView.addArrangedSubview(stopButton)
        playerControllersView.addArrangedSubview(playPauseButton)
        
        playerControllersView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(upperView.snp.bottom).offset(16)
            make.width.equalTo(self.view.frame.width / 3)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        if let pauseIcon = UIImage(named: "round_play_arrow_black_48pt"){
            playPauseButton.setImage(pauseIcon , for: .normal)
            playPauseButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        if let stopIcon = UIImage(named: "round_stop_black_48pt"){
            stopButton.setImage(stopIcon , for: .normal)
            stopButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        playPauseButton.addTarget(self, action: #selector(playPauseToggle), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(onStopButtonClicked), for: .touchUpInside)
        
        
        trimSlider = RangeSlider()
        self.view.addSubview(trimSlider)
        trimSlider.minimumValue = 0
        trimSlider.maximumValue = 100
        
        self.view.addSubview(startTimeLabel)
        startTimeLabel.text = "00:00"
        startTimeLabel.font =  getFont()
        startTimeLabel.snp.makeConstraints{ (make) -> Void in
            make.left.equalTo(self.view.snp.left).offset(16)
            make.centerY.equalTo(self.trimSlider.snp.centerY)
        }
        
        self.view.addSubview(endTimeLabel)
        endTimeLabel.text = "00:00"
        endTimeLabel.font = getFont()
        endTimeLabel.snp.makeConstraints{ (make) -> Void in
            make.right.equalTo(self.view.snp.right).offset(-16)
            make.centerY.equalTo(self.trimSlider.snp.centerY)
        }
        
        trimSlider.snp.makeConstraints{ (make) -> Void in
            make.height.equalTo(30)
            make.top.equalTo(playerControllersView.snp.bottom).offset(16)
            make.left.equalTo(startTimeLabel.snp.right).offset(8)
            make.right.equalTo(endTimeLabel.snp.left).offset(-8)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        trimSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        
        self.view.addSubview(trimHintLabel)
        trimHintLabel.text = "Move the slider thumbs to trim the sound."
        trimHintLabel.textColor = .lightGray
        trimHintLabel.font = getFont()
        trimHintLabel.textAlignment = .center
        trimHintLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.trimSlider.snp.bottom).offset(12)
            make.width.equalTo(self.view.snp.width)
        }
        
        self.view.addSubview(playBackDurationView)
        playBackDurationView.text = "Current duration: 04:58"
        playBackDurationView.font = getFont()
        playBackDurationView.textColor = .lightGray
        playBackDurationView.textAlignment = .center
        playBackDurationView.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(trimHintLabel.snp.bottom).offset(8)
            make.width.equalTo(self.view.snp.width)
        }
        
        
        playerVisibility(isHidden: true)
    }
    
    public func setUpVolumeSettingsControl(){
        volumeSegmentControl.selectedSegmentIndex = VolumeManager.defaultVolume
        self.view.addSubview(volumeSegmentControl)
        volumeSegmentControl.addTarget(self, action: #selector(onVolumeChanged), for: .valueChanged)
        volumeSegmentControl.snp.makeConstraints{ (make) -> Void in
            make.width.equalTo(self.view.snp.width).inset(UIEdgeInsets(top: 0,left: 16,bottom: 0,right: 16))
            make.top.equalTo(playBackDurationView.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        self.view.addSubview(volumeHintLabel)
        volumeHintLabel.text = "Volume relative to system sound."
        volumeHintLabel.textColor = .lightGray
        volumeHintLabel.font = getFont()
        volumeHintLabel.textAlignment = .center
        volumeHintLabel.snp.makeConstraints{ (make) -> Void in
            make.top.equalTo(self.volumeSegmentControl.snp.bottom).offset(10)
            make.width.equalTo(self.view.snp.width)
        }
        volumeHintLabel.isHidden = true
        volumeSegmentControl.isHidden = true
    }
    
    public func setUpSiriShortcutButton(){
        self.view.addSubview(addSiriShortcut)
        addSiriShortcut.setTitle("Add Siri shortcut", for: .normal)
        
        addSiriShortcut.clipsToBounds = true
        addSiriShortcut.layer.borderWidth = 0.5
        addSiriShortcut.layer.cornerRadius   = (addSiriShortcut.frame.size.width) / 2
        addSiriShortcut.layer.borderColor = UIColor.lightGray.cgColor
        
        addSiriShortcut.snp.makeConstraints{ (make) -> Void in
            make.width.equalTo(self.view.frame.width/2)
            make.top.equalTo(volumeHintLabel.snp.bottom).offset(20)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        addSiriShortcut.addTarget(self, action: #selector(presentSiriViewController), for: .touchUpInside)
        
        addSiriShortcut.isHidden = true
    }
    
    func playerVisibility(isHidden:Bool){
        playerControllersView.isHidden = isHidden
        startTimeLabel.isHidden = isHidden
        endTimeLabel.isHidden = isHidden
        trimSlider.isHidden = isHidden
        trimHintLabel.isHidden = isHidden
        playBackDurationView.isHidden = isHidden
        addSiriShortcut.isHidden = isHidden
        volumeHintLabel.isHidden = isHidden
        volumeSegmentControl.isHidden = isHidden
    }
    
    func onPlayButtonClicked(){
        if let soundFileName = currentSoundFileName{
            let startTime = TimeInterval(exactly: trimSlider.lowerValue)
            let endTime = TimeInterval(exactly: trimSlider.upperValue)
            let volume = VolumeManager.getVolumeValue(volumeSegmentControl.selectedSegmentIndex)
            AudioPlayer.sharedInstance.play(soundFileName: soundFileName,
                                            startTime: startTime,
                                            endTime: endTime,
                                            checkPlayed: true,
                                            delegate: self,
                                            volume:volume)
        }
        isPlaying = true
        showPauseIcon()
    }
    
    func onPauseButtonClicked(){
        AudioPlayer.sharedInstance.pause()
        isPlaying = false
        showPlayIcon()
    }
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        AudioPlayer.sharedInstance.stop()
        isPlaying = false
        showPlayIcon()
    }
    
    private func showPlayIcon(){
        if let playIcon = UIImage(named: "round_play_arrow_black_48pt"){
            playPauseButton.setImage(playIcon , for: .normal)
        }
    }
    
    private func showPauseIcon(){
        if let pauseIcon = UIImage(named: "round_pause_black_48pt"){
             playPauseButton.setImage(pauseIcon , for: .normal)
         }
    }
    
    @objc func playPauseToggle(_ sender: UIButton){
        if (isPlaying){
            onPauseButtonClicked()
        }else{
            onPlayButtonClicked()
        }
    }
    
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        let lowerValue = rangeSlider.lowerValue
        let upperValue = rangeSlider.upperValue
        updateStartEndTrimmingViews(start: Float(lowerValue), end: Float(upperValue))
        onStopButtonClicked(stopButton)
    }
    
    func updateStartEndTrimmingViews(start:Float, end:Float){
        AudioPlayer.sharedInstance.stop()
        self.startTimeLabel.text = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: start)
        self.endTimeLabel.text = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: end)
        let newDuration = end - start
        self.newDurationString = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: newDuration)
        self.playBackDurationView.text = "Current duration: \(newDurationString)"
    }
    
    func setUpTrimmer(_ soundOriginalDuration: Int){
        self.endTimeLabel.text = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: soundOriginalDuration)
        self.trimSlider.maximumValue = Double(soundOriginalDuration)
        self.trimSlider.minimumValue = 0
        self.trimSlider.upperValue = Double(soundOriginalDuration)
        self.trimSlider.lowerValue = 0
        self.newDurationString = AudioPlayer.sharedInstance.getFormatedTime(timeInSeconds: soundOriginalDuration)
        self.playBackDurationView.text = "Current duration: \(newDurationString)"
    }
    
    func updateThumbnail(thumbnailTime:Int64){
        SoundsFilesManger.getThumbnailImageFromVideoUrl(url: temporalFileURL, thumbnailTime: thumbnailTime) { (thumbnailImage) in
            self.updateImage(image: thumbnailImage)
        }
    }
    
    public func updateImage(image: UIImage?){
        if let i = image{
            self.currentSoundImage = i
            self.addImageButton.setImage(i, for: .normal)
        }
    }
    
    public func newSoundReady(_ newSoundFileName: String){
        if let old = self.currentSoundFileName{
            AudioPlayer.sharedInstance.stop()
            SoundsFilesManger.deleteSoundFile(old)
        }
        let soundOriginalDuration = Int(AudioPlayer.sharedInstance.getDuration(soundFileName: newSoundFileName))
        if(soundOriginalDuration == 0){
            SoundsFilesManger.deleteSoundFile(newSoundFileName)
            AlertsManager.showPlayingAlert(self)
        }else{
            
            playerVisibility(isHidden: false)
            self.currentSoundFileName = newSoundFileName
            setUpTrimmer(Int(soundOriginalDuration))
        }
    }
    
    func trimmed() -> Bool{
        guard let soundFileName = self.currentSoundFileName else{
            print("geneeratedName is empty")
            return false
        }
        let soundOriginalDuration:Int = Int(AudioPlayer.sharedInstance.getDuration(soundFileName: soundFileName))
        let newDuration = Int(trimSlider.upperValue - trimSlider.lowerValue)
        return soundOriginalDuration != newDuration
    }
    
    @objc func saveButtonClicked(_ sender: Any){
        AudioPlayer.sharedInstance.stop()
        guard let name = nameTextInput.text, name.isNotEmpty else{
            print("Name is empty")
            return
        }
        guard let soundFileName = self.currentSoundFileName else{
            print("geneeratedName is empty")
            return
        }
        if trimmed(){
            startLoadingAnimation(message: "Saving")
            let startTime = Int(trimSlider.lowerValue)
            let endTime = Int(trimSlider.upperValue)
            SoundsFilesManger.trimSound(soundFileName: soundFileName, startTime: startTime, endTime: endTime, delegate: self)
        }else{
            saveSound(name, self.currentSoundImage, soundFileName)
        }
    }
    
    @objc func cancelButtonClicked(_ sender: Any){
        if let context = extensionContext{
            context.cancelRequest(withError: NSError(domain: "com.domain.name", code: 0, userInfo: nil))
        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        if let temporalFile = temporalFileURL{
            SoundsFilesManger.deleteFile(temporalFile)
        }
        guard !soundSaved else{
            return
        }
        if let soundGeneratedName = currentSoundFileName{
            AudioPlayer.sharedInstance.stop()
            if state == .Add && isMovingFromParent{
                SoundsFilesManger.deleteSoundFile(soundGeneratedName)
            }
            if state == .ShareExtension{
                SoundsFilesManger.deleteSoundFile(soundGeneratedName)
            }
        }
    }
    
    @objc func addImageButtonClicked(_ sender: UIButton){
        let alert = UIAlertController(title:nil, message:nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default , handler:{ (UIAlertAction) in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default , handler:{ (UIAlertAction) in
            self.openGallery()
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction) in
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func openGallery(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @objc func onVolumeChanged(sender: UISegmentedControl) {
        AudioPlayer.sharedInstance.setVolume(VolumeManager.getVolumeValue(volumeSegmentControl.selectedSegmentIndex))
    }
    
    open func saveSound(_ soundName:String, _ soundImage:UIImage?, _ soundFileName:String){
        if state == .ShareExtension{
            saveNewSound(soundName, soundImage, soundFileName)
            if let context = extensionContext{
                context.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }
    
    public func saveNewSound(_ soundName:String, _ soundImage:UIImage?, _ soundFileName:String){
        let volume = VolumeManager.getVolumeValue(volumeSegmentControl.selectedSegmentIndex)
        let savedSound = CoreDataManager.shared.saveNewSound(soundName, volume, soundImage, soundFileName)
        if let sound = savedSound{
            NotificationCenter.default.post(name: Constants.soundSavedNotification, object: nil, userInfo: [Constants.soundSavedUserInfo:sound])
            soundSaved = true
        }else{
            soundSaved = false
        }
    }
    
    
    lazy var saveButton         = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonClicked))
    lazy var cancelButton         = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelButtonClicked))
    public lazy var addImageButton         = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    public lazy var nameTextInput          = UITextField()
    public lazy var volumeSegmentControl   = UISegmentedControl(items: VolumeManager.volumesTitles)
    
    
    lazy var playButton         = UIButton()
    lazy var stopButton         = UIButton()
    lazy var playPauseButton    = UIButton()
    
    lazy var playerControllersView  = UIStackView()
    lazy var trimSlider             = RangeSlider()
    lazy var startTimeLabel         = UILabel()
    lazy var endTimeLabel           = UILabel()
    lazy var playBackDurationView   = UILabel()
    lazy var trimmedDuration        = UILabel()
    lazy var trimHintLabel          = UILabel()
    lazy var addSiriShortcut        = UIButton(type: .system)
    lazy var volumeHintLabel        = UILabel()
}

extension AddEditSoundControllerBase: AudioPlayerDelegate{
    
    public func playDidStopped() {
        showPlayIcon()
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        showPlayIcon()
    }
}

extension AddEditSoundControllerBase: SoundsFilesMangerCopyDelegate{
    public func copyDidStart() {
        startLoadingAnimation(message: "Copying")
    }
    
    public func convertDidStart() {
        loadingAlert.message = "Converting"
    }
    
    public func copyAndConvertDidFinish(_ soundFileName: String, _ temporal: URL?) {
        temporalFileURL = temporal
        updateThumbnail(thumbnailTime: 1)
        stopLoadingAnimation(completion: {
            self.newSoundReady(soundFileName)
        })
    }
    
    public func copyDidFailed(_ error: Error, fileName: String) {
        stopLoadingAnimation(completion: {
            AlertsManager.showImportFailedAlert(self, fileName: fileName)
        })
    }
}

extension AddEditSoundControllerBase: UIImagePickerControllerDelegate{
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        updateImage(image: image)
    }
}

extension AddEditSoundControllerBase: SoundsFilesMangerTrimDelegate{
    public func trimDidFinished() {
        saveSound(nameTextInput.text!, currentSoundImage, currentSoundFileName!)
    }
    
    public func trimDidFailed(_ error: Error) {
        stopLoadingAnimation()
        // TODO
        print(error)
    }
}

extension AddEditSoundControllerBase: UITextFieldDelegate{
    public func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension AddEditSoundControllerBase {
    @objc func presentSiriViewController() {
        guard let soundName = nameTextInput.text, let soundFileName = currentSoundFileName else {
            return
        }
        guard soundName.isNotEmpty else{
            return
        }
        guard let playSoundActivityName = SiriExtension.getPlaySoundActivityName() else{
            return
        }
        let activity = NSUserActivity(activityType: playSoundActivityName)
        activity.title = soundName
        activity.keywords = Set([soundFileName])
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        activity.suggestedInvocationPhrase = "Play \(String(describing: soundName)) on SoundBoard"
        let viewController = INUIAddVoiceShortcutViewController(shortcut: INShortcut(userActivity: activity))
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
    }
}

extension AddEditSoundControllerBase: INUIAddVoiceShortcutViewControllerDelegate {
    public func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    public func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

extension AddEditSoundControllerBase {
    func getFont() -> UIFont{
        return UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.light)
    }
}

extension AddEditSoundControllerBase{
    public func stopLoadingAnimation(completion: (() -> Void)? = nil){
        if isLoading{
            loadingAlert.dismiss(animated: true, completion: completion)
            isLoading = false
        }else{
            if let c = completion{
                c()
            }
        }
    }
    
    public func startLoadingAnimation(message:String){
        loadingAlert.message = message
        if !isLoading{
            present(loadingAlert, animated: true, completion: nil)
            isLoading = true
        }
    }
}

extension AddEditSoundControllerBase{
    public func importURL(_ url:URL){
        let fileType = SoundsFilesManger.checkFileType(url)
        if fileType == SupportedFileTypes.unknown{
            showError(errorMessage: "The file type is not supported!")
            return
        }
        SoundsFilesManger.copyFile(url, self)
    }
}


extension AddEditSoundControllerBase: ShareExtensionHandlerDelegate{
    
    func getSharedURL(){
        ShareExtensionHandler.handle(extensionContext: extensionContext, delegate: self)
    }
    
    public func handleDidStart() {
        startLoadingAnimation(message: "Loading")
    }
    
    public func handleDidFailed() {
        showError(errorMessage: "Can't import the shared content!")
    }
    
    public func handleDidFinished(audioVideoURL: URL) {
        importURL(audioVideoURL)
    }
    
    public func handleDidFinished(youtubeURL: String) {
        YoutubeManager.downloadVideo(youtubeURL: youtubeURL, delegate: self)
    }
}

extension AddEditSoundControllerBase: YoutubeManagerDelegate{
    
    public func URLNotSupported() {
        showError(errorMessage: "Only youtube videos are supported!")
    }
    
    public func downloadDidStart() {
        self.startLoadingAnimation(message: "Downloading")
    }
    
    public func downloadDidFailed() {
        showError(errorMessage: "Can't download the video")
    }
    
    public func downloadOnProgress(_ progress: CGFloat) {
        self.startLoadingAnimation(message: "Downloading \(Int(progress * 100))%")
    }
    
    public func downloadDidFinished(_ error: Error?, _ fileUrl: URL?) {
        if let videoURL = fileUrl{
            importURL(videoURL)
        }else{
            if let e = error{
                print(e)
            }
            showError(errorMessage: "Can't download the video!")
        }
    }
}



extension AddEditSoundControllerBase{
    private func showError(errorMessage:String){
        self.stopLoadingAnimation(completion: {
            AlertsManager.showErrorAlert(self, message: errorMessage, handler: { action in
                self.cancelButtonClicked(self.cancelButton)
            })
        })
    }
}

