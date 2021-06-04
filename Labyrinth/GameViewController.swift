//
//  GameViewController.swift
//  Labyrinth
//
//  Created by Phil Stern on 5/30/21.
//
//  Blender
//  -------
//  Board with holes was created in Blender (file: "labyrinth board.blend") with the help of this video:
//    https://youtube.com/watch?v=tkbU1bGOzWM
//  The board was "unwrapped", painted, and exported to Xcode with the help of this page:
//    https://emily-45402.medium.com/building-3d-assets-in-blender-for-ios-developers-c47535755f18
//
//  I determined the board dimensions and hole locations in Photoshop using image file Board.psd
//  I used inches from Photoshop directly as meters in Blender
//  Board dimension: X = 16.9 m, Y = 14.9 m, Z = 0.1 m
//  I cut holes using a cylinder with dimensions: X = 0.8 m, Y = 0.8 m , Z = 2 m
//  To UV Unwrapped the board, I used the circumference of the upper and lower side of the holes, and one line
//    connecting upper to lower side as seams, as well as the edges and three lower sides of the board
//
//  Xcode
//  -----
//  I converted board.dae to board.scn using Xcode:  board.dae | Editor | Convert to ScneneKit file format
//  The hole center locations are the inch measurements directly from Photoshop
//  I tweaked the hole locations slightly, by uncommenting the call to createHolePanelAt in func createBoardPanels
//    and lining up the square panels with the holes
//
//  Blender axes    SceneKit axes
//      z                 y
//      |__ y         z __|
//       \                 \
//        x                 x
//
//  Notes:
//  - only use "board" mesh node from board.scn for aesthetics, since holes aren't recognized by physics body/shape
//  - created separate boardNode to add mesh, marble, and panels (covering all but holes), since nodes added to mesh node appear squashed
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

struct Constants {
    static let cameraDistance: CGFloat = 13.4  // portrait: 22.3
    static let boardWidth: CGFloat = 16.9
    static let boardHeight: CGFloat = 14.9
    static let boardThickness: CGFloat = 0.1
    static let edgeThickness: CGFloat = 0.36
    static let edgeWidth: CGFloat = 0.5
    static let marbleRadius: CGFloat = 0.32
    static let holeRadius: CGFloat = 0.434
    static let barRadius: CGFloat = 0.18
    static let panelColor = UIColor.clear
    static let boardColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)  // used for edges and walls (actual board color is in "board image.png"
    static let startingPosition = SCNVector3(x: 0.7,
                                             y: Float(Constants.boardThickness / 2 + Constants.marbleRadius),
                                             z: -Float(Constants.boardHeight / 2 - Constants.edgeWidth - Constants.marbleRadius))
}

class GameViewController: UIViewController {
    
    var scnScene: SCNScene!
    var boardNode: SCNNode!
    var marbleNode = SCNNode()
    let motionManager = CMMotionManager()  // needed for accelerometers
    
    // hole position relative to upper left corner of board
    let holeCentersX: [CGFloat] = [
        1.4, 10.4, 12.9, 14.3, 15.3, 9.1, 5.0, 2.5, 3.8, 13.1,
        10.4, 5.0, 6.5, 7.7, 10.6, 14.3, 13.1, 3.8, 11.8, 5.1,
        9.2, 1.3, 3.8, 15.1, 6.4, 5.1, 10.2, 2.4, 14.3, 13.1,
        9.1, 1.2, 3.7, 10.4, 15.2, 7.8, 2.4, 5.1, 14.3, 10.4
    ]
    let holeCentersZ: [CGFloat] = [
        1.7, 1.7, 1.7, 1.7, 2.4, 2.8, 3.4, 3.6, 3.6, 4.3,
        4.4, 5.3, 5.6, 5.6, 5.9, 6.2, 6.7, 6.9, 7.1, 7.7,
        7.8, 8.0, 9.1, 9.3, 10.1, 10.2, 10.2, 10.5, 10.8, 11.0,
        11.1, 11.6, 11.9, 12.2, 12.3, 12.5, 12.7, 13.6, 13.6, 13.6
    ]
    
    // bar end points relative to upper left corner of board
    let verticalBarCenter: [CGFloat] = [
        4.3, 9.7, 13.7, 15.0, 3.0, 4.3, 5.8, 7.0, 8.6, 12.5,
        13.8, 15.1, 3.0, 4.4, 5.8, 8.5, 15.1, 1.9, 3.1, 4.4,
        5.9, 7.1, 8.5, 12.5, 3.0, 9.6, 11.0, 13.7, 4.4, 6.0,
        8.4, 12.4, 4.2, 7.0, 13.6
    ]
    
    let horizontalBarCenter: [CGFloat] = [
        2.3, 1.9, 3.6, 3.1, 3.0, 4.9, 4.8, 5.0, 6.1, 7.8,
        9.7, 9.5, 10.0, 8.7, 10.8
    ]

    lazy var verticalBarTop: [CGFloat] = [
        Constants.edgeWidth, Constants.edgeWidth, Constants.edgeWidth, Constants.edgeWidth, 1.9, 2.4, horizontalBarCenter[1] + Constants.barRadius, 3.1, 3.1, horizontalBarCenter[4] + Constants.barRadius,
        horizontalBarCenter[4] + Constants.barRadius, 3.3, 3.9, 5.0, horizontalBarCenter[6] - Constants.barRadius, 4.8, 5.3, 7.4, 7.4, 7.1,
        7.1, 6.1, 7.1, 6.5, horizontalBarCenter[10] - Constants.barRadius, 8.4, 8.6, 7.9, 11.1, horizontalBarCenter[14] - Constants.barRadius,
        10.6, horizontalBarCenter[12] - Constants.barRadius, 13.1, 12.1, 12.5
    ]
    
    lazy var verticalBarBottom: [CGFloat] = [
        1.7, 7.4, 1.7, 1.8, 2.8, 3.4, 3.3, horizontalBarCenter[6] + Constants.barRadius, 4.0, 3.8,
        6.8, 4.2, horizontalBarCenter[8] + Constants.barRadius, 5.6, 6.0, 5.8, horizontalBarCenter[13] + Constants.barRadius, 8.6, 8.6, 8.6,
        8.6, horizontalBarCenter[11] + Constants.barRadius, 8.4, 9.0, 13.0, 10.9, horizontalBarCenter[12] + Constants.barRadius, 11.5, 12.1, 13.1,
        13.1, 13.4, 14.0, 13.3, 13.5
    ]
    
    lazy var horizontalBarLeft: [CGFloat] = [
        Constants.edgeWidth, verticalBarCenter[6] - Constants.barRadius, 1.8, verticalBarCenter[1] + Constants.barRadius, verticalBarCenter[9] - Constants.barRadius, Constants.edgeWidth, verticalBarCenter[14] + Constants.barRadius, verticalBarCenter[1] + Constants.barRadius, 1.6, 11.4,
        1.5, verticalBarCenter[21] + Constants.barRadius, verticalBarCenter[26] + Constants.barRadius, verticalBarCenter[16] + Constants.barRadius, verticalBarCenter[29] + Constants.barRadius
    ]

    lazy var horizontalBarRight: [CGFloat] = [
        1.6, verticalBarCenter[1] - Constants.barRadius, 2.1, 10.8, verticalBarCenter[10] + Constants.barRadius, 1.7, verticalBarCenter[7] - Constants.barRadius, 12.3, verticalBarCenter[12] - Constants.barRadius, verticalBarCenter[23] - Constants.barRadius,
        verticalBarCenter[24] - Constants.barRadius, 8.5, verticalBarCenter[31] - Constants.barRadius, Constants.boardWidth - Constants.edgeWidth, 7.0
    ]

    // 2D array of board locations with 0.1 resolution (origin at upper left corner)
    var taken = Array(repeating: Array(repeating: false, count: Int(Constants.boardWidth * 10)), count: Int(Constants.boardHeight * 10))  // taken[z][x]

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
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
                
        let scnView = self.view as! SCNView
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = true
        scnView.showsStatistics = false
        scnView.delegate = self  // needed to call renderer (extension, below)

        scnScene = SCNScene()
        scnView.scene = scnScene
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scnScene.rootNode.addChildNode(cameraNode)
        rotateCameraAroundBoardCenter(cameraNode: cameraNode, deltaAngle: -.pi/2)  // top view
//        rotateCameraAroundBoardCenter(cameraNode: cameraNode, deltaAngle: -.pi/3)  // sciew view

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

        let board = SCNBox(width: Constants.boardWidth,
                           height: Constants.boardThickness,
                           length: Constants.boardHeight,
                           chamferRadius: 0)
        board.firstMaterial?.diffuse.contents = UIColor.clear
        boardNode = SCNNode(geometry: board)
        boardNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scnScene.rootNode.addChildNode(boardNode)

        // extract board mesh from .scn file
        let boardScene = SCNScene(named: "art.scnassets/board.scn")!
        let boardMeshNode = boardScene.rootNode.childNode(withName: "board", recursively: true)!  // board.dae | Node inspector | Identity | Name: board
        boardNode.addChildNode(boardMeshNode)

        // cover board with kinematic panels (except for holes)
        createBoardPanels()
        createBoardEdges()
        createVerticalBoardBars()
        createHorizontalBoardBars()

        let marble = SCNSphere(radius: Constants.marbleRadius)
        marble.firstMaterial?.diffuse.contents = UIColor.white
        marbleNode = SCNNode(geometry: marble)
        marbleNode.position = Constants.startingPosition
        marbleNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boardNode.addChildNode(marbleNode)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // use accelerometers to determine direction of gravity
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let x = data?.acceleration.x, let y = data?.acceleration.y, let z = data?.acceleration.z {
                    self.scnScene.physicsWorld.gravity = SCNVector3(x: 9.8 * Float(y), y: 9.8 * Float(z), z: 9.8 * Float(x))
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopAccelerometerUpdates()
    }
    
    // MARK: - Board Creation

    private func createBoardPanels() {
        // start by marking square areas covering holes as taken
        for index in holeCentersX.indices {
//            createHolePanelAt(centerX: holeCentersX[index] - Constants.boardWidth / 2, centerZ: holeCentersZ[index] - Constants.boardHeight / 2)
            updateTakenArrayForHoleAt(centerX: holeCentersX[index], centerZ: holeCentersZ[index])
        }
        // fit panels from upper left corner of open space, to right until encountering an obstacle,
        // then down until encountering an obstacle, until all space is taken
        while true {
            if let upperLeftCorner = nextOpening() {
                let lowerRightCorner = findLowerRightCornerStartingFrom(upperLeftCorner)
                updateTakenArrayForPanelFrom(upperLeftCorner, to: lowerRightCorner)
                createBoardPanelAt(x1: CGFloat(upperLeftCorner.x) / 10 - Constants.boardWidth / 2,  // convert from upper left to board center origin
                                   x2: CGFloat(lowerRightCorner.x) / 10 - Constants.boardWidth / 2,
                                   z1: CGFloat(upperLeftCorner.z) / 10 - Constants.boardHeight / 2,
                                   z2: CGFloat(lowerRightCorner.z) / 10 - Constants.boardHeight / 2)
            } else {
                break
            }
        }
    }
    
    // move from left to right, top to bottom, to find first open location
    private func nextOpening() -> (z: Int, x: Int)? {
        for z in 0..<taken.count {
            for x in 0..<taken[0].count {
                if !taken[z][x] { return (z, x) }
            }
        }
        return nil
    }

    private func findLowerRightCornerStartingFrom(_ upperLeftCorner: (z: Int, x: Int)) -> (z: Int, x: Int) {  // origin at upper left corner of board
        var rightSide = taken[0].count
        let bottom = taken.count
        for z in upperLeftCorner.z..<bottom {
            for x in upperLeftCorner.x..<rightSide {
                if taken[z][x] {
                    if z == upperLeftCorner.z {
                        rightSide = x  // encountering obstacle in first row determines right side of opening
                    } else {
                        return (z, rightSide)  // encountering obstacle after first row determines bottom of opening
                    }
                    break
                }
            }
        }
        return (bottom, rightSide)
    }
    
    private func updateTakenArrayForHoleAt(centerX: CGFloat, centerZ: CGFloat) {  // origin at upper left corner of board
        for x in Int((centerX - Constants.holeRadius) * 10)..<Int((centerX + Constants.holeRadius) * 10) {
            for z in Int((centerZ - Constants.holeRadius) * 10)..<Int((centerZ + Constants.holeRadius) * 10) {
                taken[z][x] = true
            }
        }
    }
    
    private func updateTakenArrayForPanelFrom(_ upperLeftCorner: (z: Int, x: Int), to lowerRightCorner: (z: Int, x: Int)) {
        for x in upperLeftCorner.x..<lowerRightCorner.x {
            for z in upperLeftCorner.z..<lowerRightCorner.z {
                taken[z][x] = true
            }
        }
    }

    // this was used during development/debugging
    private func createHolePanelAt(centerX: CGFloat, centerZ: CGFloat) {  // origin at center of board
        let panel = SCNBox(width: 2 * Constants.holeRadius, height: Constants.boardThickness, length: 2 * Constants.holeRadius, chamferRadius: 0)
        panel.firstMaterial?.diffuse.contents = UIColor(displayP3Red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
        let panelNode = SCNNode(geometry: panel)
        panelNode.name = "hole"
        panelNode.position = SCNVector3(x: Float(centerX), y: 0, z: Float(centerZ))
        panelNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(panelNode)
    }

    private func createBoardPanelAt(x1: CGFloat, x2: CGFloat, z1: CGFloat, z2: CGFloat) {  // origin at center of board
        let panel = SCNBox(width: x2 - x1, height: Constants.boardThickness, length: z2 - z1, chamferRadius: 0)
        panel.firstMaterial?.diffuse.contents = Constants.panelColor
        let panelNode = SCNNode(geometry: panel)
        panelNode.position = SCNVector3(x: Float(x1 + x2) / 2, y: 0, z: Float(z1 + z2) / 2)
        panelNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(panelNode)
    }
    
    private func createBoardEdges() {  // origin at center of board
        let halfBoardWidth = Constants.boardWidth / 2
        let halfBoardHeight = Constants.boardHeight / 2
        createBoardEdge(x1: -halfBoardWidth, x2: halfBoardWidth, z1: -halfBoardHeight, z2: -halfBoardHeight + Constants.edgeWidth)  // top
        createBoardEdge(x1: -halfBoardWidth, x2: halfBoardWidth, z1: halfBoardHeight - Constants.edgeWidth, z2: halfBoardHeight)  // bottom
        createBoardEdge(x1: -halfBoardWidth, x2: -halfBoardWidth + Constants.edgeWidth, z1: -halfBoardHeight + Constants.edgeWidth, z2: halfBoardHeight - Constants.edgeWidth)  // left
        createBoardEdge(x1: halfBoardWidth - Constants.edgeWidth, x2: halfBoardWidth, z1: -halfBoardHeight + Constants.edgeWidth, z2: halfBoardHeight - Constants.edgeWidth)  // right
    }
    
    private func createBoardEdge(x1: CGFloat, x2: CGFloat, z1: CGFloat, z2: CGFloat) {  // origin at center of board
        let edge = SCNBox(width: x2 - x1, height: Constants.edgeThickness, length: z2 - z1, chamferRadius: 0)
        edge.firstMaterial?.diffuse.contents = Constants.boardColor
        let edgeNode = SCNNode(geometry: edge)
        edgeNode.position = SCNVector3(x: Float(x1 + x2) / 2,
                                       y: Float(Constants.boardThickness + Constants.edgeThickness) / 2,
                                       z: Float(z1 + z2) / 2)
        edgeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(edgeNode)
    }
    
    private func createVerticalBoardBars() {
        for index in verticalBarCenter.indices {
            createVerticalBoardBar(centerX: verticalBarCenter[index] - Constants.boardWidth / 2,
                                   top: verticalBarTop[index] - Constants.boardHeight / 2,
                                   bottom: verticalBarBottom[index] - Constants.boardHeight / 2)
        }
    }
    
    private func createHorizontalBoardBars() {
        for index in horizontalBarCenter.indices {
            createHorizontalBoardBar(centerZ: horizontalBarCenter[index] - Constants.boardHeight / 2,
                                     left: horizontalBarLeft[index] - Constants.boardWidth / 2,
                                     right: horizontalBarRight[index] - Constants.boardWidth / 2)
        }
    }

    private func createVerticalBoardBar(centerX: CGFloat, top: CGFloat, bottom: CGFloat) {  // origin at center of board
        let bar = SCNCylinder(radius: Constants.barRadius, height: bottom - top)
        bar.firstMaterial?.diffuse.contents = Constants.boardColor
        let barNode = SCNNode(geometry: bar)
        barNode.position = SCNVector3(x: Float(centerX), y: Float(Constants.boardThickness / 2 + Constants.barRadius), z: Float(top + bottom) / 2)
        barNode.transform = SCNMatrix4Rotate(barNode.transform, .pi/2, 1, 0, 0)
        barNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(barNode)
    }

    private func createHorizontalBoardBar(centerZ: CGFloat, left: CGFloat, right: CGFloat) {  // origin at center of board
        let bar = SCNCylinder(radius: Constants.barRadius, height: right - left)
        bar.firstMaterial?.diffuse.contents = Constants.boardColor
        let barNode = SCNNode(geometry: bar)
        barNode.position = SCNVector3(x: Float(left + right) / 2, y: Float(Constants.boardThickness / 2 + Constants.barRadius), z: Float(centerZ))
        barNode.transform = SCNMatrix4Rotate(barNode.transform, .pi/2, 0, 0, 1)
        barNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(barNode)
    }

    // MARK: - Miscellaneous

    // rotate camera around board x-axis, while continuing to point at board center
    private func rotateCameraAroundBoardCenter(cameraNode: SCNNode, deltaAngle: CGFloat) {
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(deltaAngle), 1, 0, 0)
        let cameraAngle = CGFloat(cameraNode.eulerAngles.x)
        cameraNode.position = SCNVector3(0, -Constants.cameraDistance * sin(cameraAngle), Constants.cameraDistance * cos(cameraAngle))
    }
    
    private func restartMarbleIfFellThroughHole() {
        if marbleNode.presentation.position.y < -10 {
            marbleNode.position = Constants.startingPosition
            marbleNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
        }
    }
}

// MARK: - Extension

extension GameViewController: SCNSceneRendererDelegate {  // set scnView.delegate = self
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        restartMarbleIfFellThroughHole()
    }
}

