//
//  GameViewController.swift
//  Labyrinth
//
//  Created by Phil Stern on 5/30/21.
//
//  Board with holes was created in Blender with the help of this video:
//    https://youtube.com/watch?v=tkbU1bGOzWM
//  The board was "unwrapped", painted, and exported to Xcode with the help of this page:
//    https://emily-45402.medium.com/building-3d-assets-in-blender-for-ios-developers-c47535755f18
//
//  I converted board.dae to board.scn:  board.dae | Editor | Convert to ScneneKit file format
//
//  Blender axes      Xcode axes
//      z                 y
//      |__ y         z __|
//       \                 \
//        x                 x
//
//  Notes:
//  - marble doesn't fall through holes in board, since physics body/shape of board covers whole board (doesn't recognize holes)
//  - I covered the board with kinematic panels (leaving the holes uncovered), adding them to scene.rootNode
//    - marble doesn't fall through panels, but panels don't rotate with board
//  - I tried adding the marble and panels to the boardNode, but everything appears squashed in the y-direction
//

import UIKit
import QuartzCore
import SceneKit

struct Constants {
    static let cameraDistance: CGFloat = 12
    static let boardThickness: CGFloat = 0.3
    static let marbleRadius: CGFloat = 0.25
}

class GameViewController: UIViewController {
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "art.scnassets/board.scn")!
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        rotateCameraAroundBoardCenter(cameraNode: cameraNode, deltaAngle: -.pi/2)  // top view
//        rotateCameraAroundBoardCenter(cameraNode: cameraNode, deltaAngle: 0)  // front view

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
//        scnView.debugOptions = .showPhysicsShapes  // pws: debugging ***************
        
        let boardNode = scene.rootNode.childNode(withName: "board", recursively: true)!  // board.dae | Node inspector | Identity | Name: board
        boardNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
//        boardNode.transform = SCNMatrix4Rotate(boardNode.transform, -0.005, 0, 0, 1)  // tip board to right
        
        createBoardPanel(x1: -3.7, x2: 0.87, z1: -3.7, z2: 3.7)
        createBoardPanel(x1: 0.87, x2: 1.44, z1: -3.7, z2: 0.75)
        createBoardPanel(x1: 0.87, x2: 1.44, z1: 1.32, z2: 3.7)
        createBoardPanel(x1: 1.44, x2: 3.7, z1: -3.7, z2: 3.7)

        let marble = SCNSphere(radius: Constants.marbleRadius)
        marble.firstMaterial?.diffuse.contents = UIColor.lightGray
        let marbleNode = SCNNode(geometry: marble)
        marbleNode.position = SCNVector3(x: 0, y: Float(Constants.boardThickness / 2 + Constants.marbleRadius), z: 1)
        marbleNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        scene.rootNode.addChildNode(marbleNode)
    }
    
    private func createBoardPanel(x1: Float, x2: Float, z1: Float, z2: Float) {
        let box = SCNBox(width: CGFloat(x2 - x1), height: Constants.boardThickness, length: CGFloat(z2 - z1), chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.blue
        let panelNode = SCNNode(geometry: box)
        panelNode.position = SCNVector3(x: (x1 + x2) / 2, y: 0, z: (z1 + z2) / 2)
        panelNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        let scnView = self.view as! SCNView
        scnView.scene?.rootNode.addChildNode(panelNode)
    }

    // rotate camera around board x-axis, while continuing to point at board center
    private func rotateCameraAroundBoardCenter(cameraNode: SCNNode, deltaAngle: CGFloat) {
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(deltaAngle), 1, 0, 0)
        let cameraAngle = CGFloat(cameraNode.eulerAngles.x)
        cameraNode.position = SCNVector3(0, -Constants.cameraDistance * sin(cameraAngle), Constants.cameraDistance * cos(cameraAngle))
    }
}
