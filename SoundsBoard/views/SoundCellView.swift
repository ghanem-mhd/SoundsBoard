//
//  SoundCellView.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 24.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import Foundation
import UIKit
import SnapKit


class SoundCellView: UITableViewCell{
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        return label
    }()
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(label)
        label.snp.makeConstraints{ (make) -> Void in
            make.centerY.equalTo(self.snp.centerY)
            make.left.equalTo(self.contentView.snp.left).offset(16)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(_ soundObject : SoundObject) {
        label.text = soundObject.name
    }
}
