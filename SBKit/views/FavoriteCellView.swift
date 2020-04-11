//
//  FavoriteCellView.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 22.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public class FavoriteCellView: UICollectionViewCell {

    static let cornerRadius:CGFloat = 10.0
    static let color:UIColor = .lightGray
    
    public let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        //label.backgroundColor = color
        label.textColor = .white
        label.layer.cornerRadius = cornerRadius
        label.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        label.layer.masksToBounds = true
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        return label
    }()
    
    public let image: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = cornerRadius
        image.layer.masksToBounds = true
        return image
    }()
    
    
    public let playIcon: UIImageView = {
        let image = UIImageView()
        image.isHidden = true
        if let playIcon = UIImage(named:"round_play_arrow_black_48pt"){
            image.image = playIcon
        }
        image.tintColor = .white
        return image
    }()
    
    public let blacklayer: UIView = {
        let layer = UIView()
        layer.backgroundColor = .black
        layer.alpha = 0.35
        layer.layer.cornerRadius = cornerRadius
        layer.layer.masksToBounds = true
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = FavoriteCellView.cornerRadius
        self.layer.borderWidth = 1.5
        self.layer.borderColor = FavoriteCellView.color.cgColor

        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 2.0, height: 4.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 1.0
        self.layer.masksToBounds = false
        
        
        addSubview(image)
        image.snp.makeConstraints{ (make) -> Void in
            make.edges.equalTo(self)
        }
        
        addSubview(blacklayer)
        blacklayer.snp.makeConstraints{ (make) -> Void in
            make.edges.equalTo(self)
        }
        
        addSubview(label)
        label.snp.makeConstraints{ (make) -> Void in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
            //make.bottom.equalTo(self.snp.bottom)
            make.width.equalTo(self.frame.width)
        }
        addSubview(playIcon)
        playIcon.snp.makeConstraints{ (make) -> Void in
            make.width.height.equalTo(50)
            make.center.equalTo(self.snp.center)
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(_ soundObject : SoundObject) {
        label.text = soundObject.name
        if let soundImageData = soundObject.image{
            image.image = UIImage(data: soundImageData)
        }
    }
    
    

}
