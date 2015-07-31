//
//  IMGLYStickersDataSource.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 23/03/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public protocol IMGLYStickersDataSourceDelegate: class, UICollectionViewDataSource {
    var stickers: [IMGLYSticker] { get }
}

public class IMGLYStickersDataSource: NSObject, IMGLYStickersDataSourceDelegate {
    public let stickers: [IMGLYSticker]
    
    override init() {
        let stickerFiles = [
            "sticker01",
            "sticker02",
            "sticker03",
            "sticker04",
            "sticker05",
            "sticker06",
            "sticker07",
            "sticker08",
            "sticker09",
            "sticker10",
            "sticker11",
            "sticker12",
            "sticker13",
            "sticker14",
            "sticker15",
            "sticker16",
            "sticker17",
            "sticker18",
            "sticker19",
            "sticker20",
            "sticker21",
            "sticker22",
            "sticker23",
            "sticker24",
            "sticker25",
            "sticker26",
            "sticker27",
            "sticker28",
            "sticker29",
            "sticker30",
            "sticker31",
            "sticker32",
            "sticker33",
            //"glasses_nerd",
            //"glasses_normal",
            //"glasses_shutter_green",
            //"glasses_shutter_yellow",
            //"glasses_sun",
            //"hat_cap",
            //"hat_party",
            //"hat_sherrif",
            //"hat_zylinder",
            //"heart",
            //"mustache_long",
            //"mustache1",
            //"mustache2",
            //"mustache3",
            //"pipe",
            //"snowflake",
            //"star"
        ]
        
        stickers = stickerFiles.map { file in
            if let image = UIImage(named: file, inBundle: NSBundle(forClass: IMGLYStickersDataSource.self), compatibleWithTraitCollection: nil) {
                let thumbnail = UIImage(named: file + "_thumbnail", inBundle: NSBundle(forClass: IMGLYStickersDataSource.self), compatibleWithTraitCollection: nil)
                return IMGLYSticker(image: image, thumbnail: thumbnail)
            }
            
            return nil
            }.filter { $0 != nil }.map { $0! }
        
        super.init()
    }
    
    init(stickers: [IMGLYSticker]) {
        self.stickers = stickers
        super.init()
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(StickersCollectionViewCellReuseIdentifier, forIndexPath: indexPath) as! IMGLYStickerCollectionViewCell
        
        cell.imageView.image = stickers[indexPath.row].thumbnail ?? stickers[indexPath.row].image
        
        return cell
    }
}
