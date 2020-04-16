//
//  SoundCellView.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 24.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit
import SBKit
import SnapKit


class SoundCellView: UITableViewCell{
    
    static let cornerRadius:CGFloat = 10.0
    
     var favoriteClick : (() -> ())?
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        return label
    }()
    
    public let favoriteClickArea: UIView = {
        let uiView = UIView()
        return uiView
    }()
    
    public let favoriteImage: UIButton = {
        let favoriteImage = UIButton()
        favoriteImage.tintColor = .systemRed
        favoriteImage.contentMode = .scaleAspectFit
        favoriteImage.isUserInteractionEnabled = false
        return favoriteImage
    }()
    
    
    public let soundImage: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = cornerRadius
        image.layer.masksToBounds = true
        return image
    }()
    
    @objc func buttonClicked() {
        favoriteClick?()
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        addSubview(soundImage)
        soundImage.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.snp.centerY)
            make.left.equalTo(self.contentView.snp.left).offset(16)
            make.height.width.equalTo(self.contentView.snp.height).offset(-16)
        }
        
        
        addSubview(label)
        label.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.snp.centerY)
            make.left.equalTo(self.soundImage.snp.right).offset(16)
        }
        
        addSubview(favoriteImage)
        favoriteImage.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.snp.centerY)
            make.height.width.equalTo(self.contentView.snp.height).offset(-16)
            make.right.equalTo(self.contentView.snp.right).offset(-16)
        }
        
        addSubview(favoriteClickArea)
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.buttonClicked))
        favoriteClickArea.addGestureRecognizer(gesture)

        favoriteClickArea.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(self.contentView.snp.height)
            make.width.equalTo(self.contentView.snp.height).offset(16)
            make.right.equalTo(self.contentView.snp.right)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(_ soundObject : SoundObject) {
        label.text = soundObject.name
        if let soundImageData = soundObject.image{
            soundImage.image = UIImage(data: soundImageData)
        }else{
            if let placeholder = UIImage(named: "baseline_image_black_48pt"){
                soundImage.image = placeholder
                soundImage.contentMode = .scaleToFill
            }
        }
        if soundObject.isFavorite{
            favoriteImage.setImage(UIImage(named: "round_favorite_black_48pt"), for: .normal)
        }else{
            favoriteImage.setImage(UIImage(named: "round_favorite_border_black_48pt"), for: .normal)
        }
    }
}
