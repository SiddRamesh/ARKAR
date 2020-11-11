//
//  ViewController.swift
//  ARKAR
//
//  Created by Ramesh Siddanavar on 07/11/20.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion

// Convert Degrees to Radians
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle = SCNPhysicsVehicle()
    var orientation: CGFloat = 0
    var touched:Int = 0
    
    // [Acceleration due to gravity in x-direction, Acceleration due to gravity in y-direction]
    var accelerationValues = [UIAccelerationValue(0),UIAccelerationValue(0)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
        // session configured to detect horizontal surfaces
        self.configuration.planeDetection = .horizontal
        self.setupAccelerometer()
        
        // Create a new scene i.e
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
//        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - RENDERER
    
    // Function to Create a Concrete Floor
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode{
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        // Make Concrete Plane static (fixed) to support other bodies on top of it
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians,0,0)
        return concreteNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // If the Anchor added was a plane anchor, this statement will succeed
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
        print("New Horizontal surface detected, ARPlaneAnchor Added")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // planeAnchor contains Orientation, position and size of a Horizontal Surface
        // As it gets to see more of floor, it updates its anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print("Updating Floor's Anchor...")
        node.enumerateChildNodes{(childNode,_) in
            childNode.removeFromParentNode()
        }
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        print("Removed Second ARPlane Anchor !!")
        node.enumerateChildNodes{(childNode,_) in
            childNode.removeFromParentNode()
        }
    }
    
    
    // MARK: - LOAD OBJ
    
    // Add Car after the Plane is detected.
    @IBAction func addCar(_ sender: Any) {
        
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        // Orientation of Camera
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        // Location of Camera
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        // Final Position of Camera
        let currentCameraPosition = addVectors(firstVector: orientation, secondVector: location)
        
        // Add Car Scene
        let carScene = SCNScene(named: "Aston")
        // Add car node to the Scene
        // The frame contains the wheels and body of car.
        // So, the frame is the parent of the wheels and body. Wherever parent goes, the children follow. So, calling parent works here.
        let chassi = (carScene?.rootNode.childNode(withName: "Aston", recursively: false))!
        
        // Define front and rear wheels as children of the frame
        let frontLeftWheel = chassi.childNode(withName: "Wheel_FL", recursively: false)
        let frontRightWheel = chassi.childNode(withName: "Wheel_FR", recursively: false)
        let rearLeftWheel = chassi.childNode(withName: "Wheel_RL", recursively: false)
        let rearRightWheel = chassi.childNode(withName: "Wheel_RR", recursively: false)
        
        // Make the rear and front wheels a Vechicle wheel to make the car act like a vehicle in the physics world
        let vehcle_frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheel!)
        let vehcle_frontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheel!)
        let vehcle_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeftWheel!)
        let vehcle_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel!)
        // let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        // Give the box a Physical Body and Gravity
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassi, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        chassi.physicsBody = body
        // Give a Mass to the Car
        body.mass = 1    // default value
        // Add these to make our car in scene act like a Vehicle
        // Provides an engine to our car
        self.vehicle = SCNPhysicsVehicle(chassisBody: chassi.physicsBody!, wheels: [vehcle_rearLeftWheel,vehcle_rearRightWheel,vehcle_frontLeftWheel,vehcle_frontRightWheel])
        // Add vehicle behavior to our car in Physics world
        self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
        // Color across surface of box
        // box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        chassi.position = currentCameraPosition
        self.sceneView.scene.rootNode.addChildNode(chassi)
    }
    
    // Function to add two vectors
    func addVectors(firstVector: SCNVector3,secondVector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(firstVector.x + secondVector.x, firstVector.y + secondVector.y, firstVector.z + secondVector.z)
    }
    
    // Function to use Accelerometer to drive the Car
    func setupAccelerometer(){
        // Accelerometer data update interval
        motionManager.accelerometerUpdateInterval = 1/60
        // if accelerometer available on device
        if motionManager.isAccelerometerAvailable{
            // Start detecting the Acceleration
            motionManager.startAccelerometerUpdates(to: .main, withHandler:
                {(accelerometerData,error) in
                    if let error = error{
                        print(error.localizedDescription)
                        return
                    }
                    self.accelerometerDidChange(acceleration: (accelerometerData?.acceleration)!)
            })
        }
        else{
            print("Accelerometer not available !!")
        }
    }
    
    // use the Accelerometer data
    func accelerometerDidChange(acceleration: CMAcceleration){
        // if acceleration.x == 1; all acceleration is applied in horizontal direction
        // if acceleration.y == 1; all acceleration is applied in vertical direction
        print("x acc.: ",acceleration.x)
        print("y acc.: ",acceleration.y)
        print("")
        accelerationValues[1] = filtered(previousAcceleration: accelerationValues[1], UpdatedAcceleration: acceleration.y)
        accelerationValues[0] = filtered(previousAcceleration: accelerationValues[0], UpdatedAcceleration: acceleration.x)
        // To avoid the left/right flipping when phone is rotated 180 degrees and x = +ve
        if accelerationValues[0] > 0{
            self.orientation = -CGFloat(accelerationValues[1])
        }
        else{
            self.orientation = CGFloat(accelerationValues[1])
        }
    }
    
    // This delegate function gets called 60 times per second based on 60fps
    // So, any change made in this function to scene gets reflected immidiately in the scene
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        var engineForce: CGFloat = 0
        var brakingForce: CGFloat = 0
        // Whatever behavior we set to the "vehicle", it applies to the whole car
        // Change steering angle of front left wheel by change in phone's accelerometer value along y axis
        self.vehicle.setSteeringAngle(-orientation, forWheelAt: 2)
        // Change steering angle of front right wheel by change in phone's accelerometer value along y axis
        self.vehicle.setSteeringAngle(-orientation, forWheelAt: 3)
        
        // Check if screen was touched or not
        switch self.touched {
        case 1:
            // If screen is touched, set force to 5 Newtons
            engineForce = 5 // Newtons
        case 2:
            engineForce = -5
        case 3:
            brakingForce = 100
        default:
            engineForce = 0
        }
        
        // Apply this engine force to our car's back wheels
        // Apply engine force to rear left wheel
        self.vehicle.applyEngineForce(CGFloat(engineForce), forWheelAt: 0)
        // Apply engine force to rear right wheel
        self.vehicle.applyEngineForce(CGFloat(engineForce), forWheelAt: 1)
        
        // Apply braking force to back wheels of car
        // Apply braking force to rear left wheel
        self.vehicle.applyBrakingForce(CGFloat(brakingForce), forWheelAt: 0)
        // Apply braking force to rear right wheel
        self.vehicle.applyBrakingForce(CGFloat(brakingForce), forWheelAt: 1)
        
    }
    
    // Function to filter out the Acceleration so that we only get the acceleration due to horizontal/vertical orientation and not due to motion
    func filtered(previousAcceleration: Double, UpdatedAcceleration: Double) -> Double {
        let kfilteringFactor = 0.5
        return UpdatedAcceleration * kfilteringFactor + previousAcceleration * (1-kfilteringFactor)
    }
    
    // Function to drive the car on touching the Phone Screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard  let _ = touches.first else {return}
        // Count how many fingers are touching the screen
        self.touched += touches.count
    }
    
    // Function to Stop the Car on leaving the touch from screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touched = 0
    }
    
}
