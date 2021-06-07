//
//  Hud.swift
//  Labyrinth
//
//  Created by Phil Stern on 6/7/21.
//

import Foundation
import SpriteKit

class Hud: SKScene {

    var raceTime = 0.0 {
        didSet {
            raceTimeLabel.text = minDecimalSecFromSeconds(raceTime)
        }
    }
    
    let raceTimeLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    func setup() {
        raceTimeLabel.position = CGPoint(x: 0.5 * frame.width, y: 0.957 * frame.height)  // center top
        raceTimeLabel.fontSize = frame.height / 32
        addChild(raceTimeLabel)
        raceTime = 0.0
    }
    
    private func minDecimalSecFromSeconds(_ seconds: Double) -> String {
        let min = Int(seconds / 60)
        let sec = seconds - Double(min * 60)
        return seconds > 60 ? String(format: "%2d:%0.1f", min, sec) : String(format: "%.1f", sec)
    }
}
