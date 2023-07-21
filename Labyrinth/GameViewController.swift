//
//  GameViewController.swift
//  Labyrinth
//
//  Created by Phil Stern on 5/30/21.
//
//  To force landscape on iPad, go to: TARGETS | General | Deployment Info
//  - Uncheck: iPhone (leave iPad checked)...
//  - Uncheck: Portrait, Upside Down, and Landscape Right
//  - Check: Requires full screen (or you will get error saying all orientations must be supported when submitting app for review)
//  - Recheck: iPhone
//
//  Device orientations:
//    In addition to the Device Orientations properties under Targets | General, there may be
//    left-over/redundant settings in: Targets | Build Settings | Info.plist Values.  I had to
//    delete the settings labeled: "Supported Interface Orientations (iPhone)", so that the
//    iPhone would use the settings labeled: "Supported Interface Orientations"
//
//  Blender
//  -------
//  Board with holes was created in Blender (file: "labyrinth board.blend") with the help of this video:
//    https://youtube.com/watch?v=tkbU1bGOzWM
//  The board was "unwrapped", painted, and exported to Xcode with the help of this page:
//    https://emily-45402.medium.com/building-3d-assets-in-blender-for-ios-developers-c47535755f18
//
//    *** Warning ***    Accept the default unwrapping.  Manually marking the seams causes all kinds of distortion.
//
//  I determined the board dimensions and hole locations in Photoshop using image file Board.psd
//  I used inches from Photoshop directly as meters in Blender
//  Board dimension: X = 13.8 m, Y = 10.9 m, Z = 0.1 m
//  I cut holes using a cylinder with dimensions: X = 0.62 m, Y = 0.62 m , Z = 2 m
//
//  Xcode
//  -----
//  After adding board.dae and "board image.png" to Xcode, select the board in board.dae
//    Select: Material inspector | diffuse | "board image.png"
//    Enter: Node inspector | Name | board
//    Select: Editor (top menu) | Convert to ScneneKit file format
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
import CoreMotion  // needed for accelerometers

struct Constants {
    static let gravity = 20.0  // m/s^2 (boosted for better performance)
    static let cameraDistance: CGFloat = 10.0
    static let boardWidth: CGFloat = 13.8
    static let boardHeight: CGFloat = 10.9
    static let boardThickness: CGFloat = 0.1
    static let edgeThickness: CGFloat = 0.28  // raised edge to keep marble on board
    static let edgeWidth: CGFloat = 0.40
    static let marbleRadius: CGFloat = 0.23
    static let holeRadius: CGFloat = 0.40
    static let barRadius: CGFloat = 0.14
    static let panelColor = UIColor.clear  // use .blue for debugging (and set boardThickness to 0.2)
    static let boardColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)  // used for edges and walls (actual board color is in "board image.png")
    static let startingPosition = SCNVector3(x: 0.6,  // origin at center of board
                                             y: Float(Constants.boardThickness / 2 + Constants.marbleRadius),
                                             z: Float(-Constants.boardHeight / 2 + Constants.edgeWidth + 1.7 * Constants.marbleRadius))
}

class GameViewController: UIViewController {
    
    var scnScene: SCNScene!
    var boardNode: SCNNode!
    var marbleNode = SCNNode()
    var hud = Hud()
    let motionManager = CMMotionManager()  // needed for accelerometers
    var timerRunning = false
    var startTime = 0.0
    
    // hole position relative to upper left corner of board
    let holeCentersX: [CGFloat] = [
        1.0, 2.0, 2.9, 4.1, 7.4, 8.6, 10.8, 12.0, 13.0, 4.1,
        5.2, 6.3, 8.6, 10.8, 8.5, 9.6, 10.8, 11.9, 0.8, 2.9,
        4.0, 7.4, 0.8, 1.8, 2.9, 1.8, 2.9, 4.0, 5.1, 4.0,
        6.1, 7.3, 8.4, 8.5, 8.5, 10.7, 11.9, 12.8, 11.9, 12.9
    ]
    let holeCentersZ: [CGFloat] = [
        0.9, 2.3, 2.2, 2.2, 1.8, 0.9, 0.9, 0.9, 1.5, 3.7,
        3.8, 3.8, 2.9, 2.6, 4.1, 4.9, 4.7, 4.2, 5.7, 4.8,
        5.5, 5.5, 8.5, 7.6, 6.7, 9.4, 8.8, 7.5, 7.3, 10.0,
        9.2, 8.1, 7.3, 8.9, 10.1, 7.9, 7.8, 6.8, 10.1, 8.8
    ]
    
    // bar centerlines relative to upper left corner of board
    let verticalBarCenter: [CGFloat] = [
        3.55, 7.9, 11.4, 12.6, 2.4, 3.55, 4.7, 5.8, 6.9, 10.2,
        11.3, 12.4, 2.4, 3.55, 4.7, 6.9, 12.4, 1.5, 2.5, 3.5,
        4.6, 5.7, 6.8, 10.2, 2.4, 7.8, 9.0, 11.2, 3.5, 4.5,
        6.7, 10.1, 3.5, 5.6, 11.3
    ]
    
    let horizontalBarCenter: [CGFloat] = [
        1.4, 1.3, 2.3, 2.0, 2.0, 3.3, 3.3, 3.5, 4.3, 5.4,
        7.0, 6.8, 7.4, 6.2, 7.9, 9.5
    ]

    // bar end-points relative to upper left corner of board
    lazy var verticalBarTop: [CGFloat] = [
        Constants.edgeWidth, Constants.edgeWidth, Constants.edgeWidth, Constants.edgeWidth, 1.3, 1.9, horizontalBarCenter[1] + Constants.barRadius, 2.2, 2.0, horizontalBarCenter[4] + Constants.barRadius,
        horizontalBarCenter[4] + Constants.barRadius, 1.9, 2.7, 3.2, horizontalBarCenter[6] - Constants.barRadius, 3.4, 3.6, 5.1, 5.1, 5.0,
        5.0, 4.2, 5.0, 4.4, horizontalBarCenter[10] - Constants.barRadius, 5.9, 6.2, 5.7, 8.3, horizontalBarCenter[14] - Constants.barRadius,
        7.8, horizontalBarCenter[12] - Constants.barRadius, 9.8, 8.8, 9.1
    ]
    
    lazy var verticalBarBottom: [CGFloat] = [
        1.2, 5.2, 1.0, 1.0, 1.9, 2.5, 2.2, horizontalBarCenter[6] + Constants.barRadius, 2.6, 2.7,
        4.8, 2.9, horizontalBarCenter[8] + Constants.barRadius, 3.9, 4.1, 4.2, horizontalBarCenter[13] + Constants.barRadius, 6.1, 6.1, 6.3,
        6.3, horizontalBarCenter[11] + Constants.barRadius, 5.9, 6.3, 9.7, 7.8, horizontalBarCenter[12] + Constants.barRadius, 8.3, 9.1, 9.6,
        9.6, 9.6, Constants.boardHeight - Constants.edgeWidth, 9.7, 9.7
    ]
    
    lazy var horizontalBarLeft: [CGFloat] = [
        Constants.edgeWidth, verticalBarCenter[6] - Constants.barRadius, 1.3, verticalBarCenter[1] + Constants.barRadius, verticalBarCenter[9] - Constants.barRadius, Constants.edgeWidth, verticalBarCenter[14] + Constants.barRadius, verticalBarCenter[1] + Constants.barRadius, 1.2, 9.0,
        1.2, verticalBarCenter[21] + Constants.barRadius, verticalBarCenter[26] + Constants.barRadius, verticalBarCenter[16] + Constants.barRadius, verticalBarCenter[29] + Constants.barRadius, 7.7
    ]

    lazy var horizontalBarRight: [CGFloat] = [
        1.1, verticalBarCenter[1] - Constants.barRadius, 1.6, 9.1, verticalBarCenter[10] + Constants.barRadius, 1.4, verticalBarCenter[7] - Constants.barRadius, 10.1, verticalBarCenter[12] - Constants.barRadius, verticalBarCenter[23] - Constants.barRadius,
        verticalBarCenter[24] - Constants.barRadius, 6.9, verticalBarCenter[31] - Constants.barRadius, Constants.boardWidth - Constants.edgeWidth, 5.6, 9.1
    ]

    // 2D array of board locations with 0.1 inch resolution (origin at upper left corner)
    var taken = Array(repeating: Array(repeating: false, count: Int(Constants.boardWidth * 10)), count: Int(Constants.boardHeight * 10))  // taken[z][x]
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
                
        let scnView = self.view as! SCNView
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.delegate = self  // needed to call renderer (extension, below)

        scnScene = SCNScene()
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
        
        hud = Hud(size: view.bounds.size)
        hud.setup()
        hud.bestTime = UserDefaults.standard.double(forKey: "time")  // 0, if not found
        scnView.overlaySKScene = hud

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
        
        scnView.prepare(scnScene!, shouldAbortBlock: nil)  // this causes scene to appear right when launch screen clears
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // use accelerometers to determine direction of gravity
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let x = data?.acceleration.x, let y = data?.acceleration.y, let z = data?.acceleration.z {
                    self.scnScene.physicsWorld.gravity = SCNVector3(x: Float(Constants.gravity * y), y: Float(Constants.gravity * z), z: Float(Constants.gravity * x))
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
    
    // print subset of taken array (for debugging)
    private func printTakenArray() {
        print()
        for z in 0..<60 {
            print()
            for x in 0..<80 {
                print(taken[z][x] ? "x" : ".", terminator: "")
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

    // use for development/debugging, to see if hole centers align with "board image.png"
    // and if board panels butt up against them (change Constants.panelColor to blue)
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
        barNode.transform = SCNMatrix4Rotate(barNode.transform, .pi/2, 1, 0, 0)
        barNode.position = SCNVector3(x: Float(centerX), y: Float(Constants.boardThickness / 2 + Constants.barRadius), z: Float(top + bottom) / 2)
        barNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(barNode)
    }

    private func createHorizontalBoardBar(centerZ: CGFloat, left: CGFloat, right: CGFloat) {  // origin at center of board
        let bar = SCNCylinder(radius: Constants.barRadius, height: right - left)
        bar.firstMaterial?.diffuse.contents = Constants.boardColor
        let barNode = SCNNode(geometry: bar)
        barNode.transform = SCNMatrix4Rotate(barNode.transform, .pi/2, 0, 0, 1)
        barNode.position = SCNVector3(x: Float(left + right) / 2, y: Float(Constants.boardThickness / 2 + Constants.barRadius), z: Float(centerZ))
        barNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        boardNode.addChildNode(barNode)
    }

    // MARK: - Miscellaneous

    // rotate camera around board x-axis, while continuing to point at board center
    private func rotateCameraAroundBoardCenter(cameraNode: SCNNode, deltaAngle: CGFloat) {  // deltaAngle in radians
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(deltaAngle), 1, 0, 0)
        let cameraAngle = CGFloat(cameraNode.eulerAngles.x)
        cameraNode.position = SCNVector3(0, -Constants.cameraDistance * sin(cameraAngle), Constants.cameraDistance * cos(cameraAngle))
    }
    
    // MARK: - Timer Functions
    
    private func restartMarbleIfFellThroughHole() {
        if marbleNode.presentation.position.y < -10 {
            marbleNode.position = Constants.startingPosition
            marbleNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: 0)
            timerRunning = false
            hud.raceTime = 0.0
        }
    }
    
    private func checkRaceStart(time: TimeInterval) {
        if marbleNode.presentation.position.x < Constants.startingPosition.x - 1 {
            timerRunning = true
            startTime = time
        }
    }
    
    private func checkRaceFinish() {
        let marbleX = CGFloat(marbleNode.presentation.position.x) + Constants.boardWidth / 2  // origin at upper left corner of board
        let marbleZ = CGFloat(marbleNode.presentation.position.z) + Constants.boardHeight / 2
        if marbleX > verticalBarCenter[16] && marbleZ > horizontalBarCenter[13] - 1 && marbleZ < horizontalBarCenter[13] {
            timerRunning = false
            if hud.raceTime < hud.bestTime || hud.bestTime == 0.0 {
                UserDefaults.standard.set(hud.raceTime, forKey: "time")
                hud.bestTime = hud.raceTime
            }
        }
    }
}

// MARK: - Extension

extension GameViewController: SCNSceneRendererDelegate {  // requires setting scnView.delegate = self, above
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if timerRunning {
            hud.raceTime = time - startTime
            checkRaceFinish()
        } else {
            checkRaceStart(time: time)
        }
        restartMarbleIfFellThroughHole()
    }
}
