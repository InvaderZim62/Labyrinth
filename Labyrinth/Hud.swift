//
//  Hud.swift
//  Labyrinth
//
//  Created by Phil Stern on 6/7/21.
//
//  Hud has two labels and no buttons (see Tetris and Domino Draw for examples of Huds with buttons).
//

import Foundation
import SpriteKit

class Hud: SKScene {

    var raceTime = 0.0 {
        didSet {
            raceTimeLabel.text = minDecimalSecFromSeconds(raceTime)
        }
    }

    var bestTime = 0.0 {
        didSet {
            bestTimeLabel.text = "Best Time \(minDecimalSecFromSeconds(bestTime))"
        }
    }

    let raceTimeLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let bestTimeLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    func setup() {
        let fontSize = max(frame.height / 34, 14)
        let upperEdge = 0.955 * frame.height
        
        raceTimeLabel.position = CGPoint(x: 0.50 * frame.width, y: upperEdge)
        raceTimeLabel.fontSize = fontSize
        addChild(raceTimeLabel)
        raceTime = 0.0
        
        bestTimeLabel.position = CGPoint(x: 0.74 * frame.width, y: upperEdge)
        bestTimeLabel.fontSize = fontSize
        addChild(bestTimeLabel)
        bestTime = 0.0
    }
    
    private func minDecimalSecFromSeconds(_ seconds: Double) -> String {
        let min = Int(seconds / 60)
        let sec = seconds - Double(min * 60)
        return seconds > 60 ? String(format: "%d:%0.1f", min, sec) : String(format: "%.1f", sec)
    }
}
