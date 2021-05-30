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
//  - only used the board mesh node from the .scn file for aesthetics, since the holes aren't recognized by the physics body/shape
//  - created a separate board node to add mesh, marble, and panels (coving all but holes), since adding nodes to mesh node appear squashed
//

import UIKit
import QuartzCore
import SceneKit

struct Constants {
    static let cameraDistance: CGFloat = 12
    static let boardThickness: CGFloat = 0.3
    static let marbleRadius: CGFloat = 0.25
    static let panelColor = UIColor.clear
}

class GameViewController: UIViewController {
    
    var boardNode: SCNNode!

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
                
        let scnView = self.view as! SCNView
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        
        let scnScene = SCNScene()
        scnView.scene = scnScene
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scnScene.rootNode.addChildNode(cameraNode)
        rotateCameraAroundBoardCenter(cameraNode: cameraNode, deltaAngle: -.pi/2)  // top view

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scnScene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scnScene.rootNode.addChildNode(ambientLightNode)

        let board = SCNBox(width: 7.4, height: Constants.boardThickness, length: 7.4, chamferRadius: 0)
        board.firstMaterial?.diffuse.contents = UIColor.clear
        boardNode = SCNNode(geometry: board)
        boardNode.position = SCNVector3(x: 0, y: 0, z: 0)
        boardNode.transform = SCNMatrix4Rotate(boardNode.transform, -0.02, 0, 0, 1)  // tip board to right
        scnScene.rootNode.addChildNode(boardNode)

        // extract board mesh from .scn file
        let boardScene = SCNScene(named: "art.scnassets/board.scn")!
        let boardMeshNode = boardScene.rootNode.childNode(withName: "board", recursively: true)!  // board.dae | Node inspector | Identity | Name: board
        boardNode.addChildNode(boardMeshNode)

        // cover board with kinematic panels (except for holes)
        createBoardPanel(x1: -3.7, x2: -2.1, z1: -3.7, z2: 3.7)
        createBoardPanel(x1: -2.1, x2: -1.53, z1: -3.7, z2: 1.94)
        createBoardPanel(x1: -2.1, x2: -1.53, z1: 2.51, z2: 3.7)

        createBoardPanel(x1: -1.53, x2: -1.0, z1: -3.7, z2: 3.7)
        createBoardPanel(x1: -1.0, x2: -0.43, z1: -3.7, z2: -2.39)
        createBoardPanel(x1: -1.0, x2: -0.43, z1: -1.82, z2: 3.7)

        createBoardPanel(x1: -0.43, x2: 0.87, z1: -3.7, z2: 3.7)
        createBoardPanel(x1: 0.87, x2: 1.44, z1: -3.7, z2: 0.75)
        createBoardPanel(x1: 0.87, x2: 1.44, z1: 1.32, z2: 3.7)
        
        createBoardPanel(x1: 1.44, x2: 3.7, z1: -3.7, z2: 3.7)

        let marble = SCNSphere(radius: Constants.marbleRadius)
        marble.firstMaterial?.diffuse.contents = UIColor.lightGray
        let marbleNode = SCNNode(geometry: marble)
        marbleNode.position = SCNVector3(x: 0, y: Float(Constants.boardThickness / 2 + Constants.marbleRadius), z: 1)
        marbleNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boardNode.addChildNode(marbleNode)
    }
    
    private func createBoardPanel(x1: Float, x2: Float, z1: Float, z2: Float) {
        let box = SCNBox(width: CGFloat(x2 - x1), height: Constants.boardThickness, length: CGFloat(z2 - z1), chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = Constants.panelColor
        let panelNode = SCNNode(geometry: box)
        panelNode.position = SCNVector3(x: (x1 + x2) / 2, y: 0, z: (z1 + z2) / 2)
        panelNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(panelNode)
    }

    // rotate camera around board x-axis, while continuing to point at board center
    private func rotateCameraAroundBoardCenter(cameraNode: SCNNode, deltaAngle: CGFloat) {
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(deltaAngle), 1, 0, 0)
        let cameraAngle = CGFloat(cameraNode.eulerAngles.x)
        cameraNode.position = SCNVector3(0, -Constants.cameraDistance * sin(cameraAngle), Constants.cameraDistance * cos(cameraAngle))
    }
}
