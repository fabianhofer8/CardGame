//
//  ViewController.swift
//  CardGame
//
//  Created by Simon Puchner on 12.04.22.
//

import UIKit
import RealityKit
import SceneKit.ModelIO
//import ARKit


class ViewController: UIViewController {
    
   // @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var arView: ARView!
    
    var positions: [position] = [] // positions for cards
    var cardsAnchor: AnchorEntity = AnchorEntity() // anchor entity for cards
    var openCards: [Entity] = [] // already opened cards
    var values: [Int:String] = [:] // 16 cards to play with eg: key: 0, value: "Cross 9"
    var displayedCards: [Entity] = [] // the 16 cards which are currently displayed (open / hidden)
    var buttons: [Entity] = [] // the buttons to work with
    var currentVal: Int = 0 // value of last open card
    var firstGame: Bool = true // in case we want to restart
    var isAlive: Bool = true // check if game is still alive
    var higherLower: String = "lower" // the current answer
    var currentRow: Int = 1
    
    override func viewDidLoad() {
        
        // cards
        positions.append(position(_x: 0, _y: 0, _z: 2))
        positions.append(position(_x: -0.5, _y: 0, _z: 1))
        positions.append(position(_x: 0.5, _y: 0, _z: 1))
        positions.append(position(_x: -1, _y: 0, _z: 0))
        positions.append(position(_x: 0, _y: 0, _z: 0))
        positions.append(position(_x: 1, _y: 0, _z: 0))
        positions.append(position(_x: -1.5, _y: 0, _z: -1))
        positions.append(position(_x: -0.5, _y: 0, _z: -1))
        positions.append(position(_x: 0.5, _y: 0, _z: -1))
        positions.append(position(_x: 1.5, _y: 0, _z: -1))
        positions.append(position(_x: -1, _y: 0, _z: -2))
        positions.append(position(_x: 0, _y: 0, _z: -2))
        positions.append(position(_x: 1, _y: 0, _z: -2))
        positions.append(position(_x: -0.5, _y: 0, _z: -3))
        positions.append(position(_x: 0.5, _y: 0, _z: -3))
        positions.append(position(_x: 0, _y: 0, _z: -4))
        
        super.viewDidLoad()
        
        
        initCards()
        initScene()
        //initModels()
        
        
    }
    
    /**
     Add some models to the scene
     */
    func initModels(){
        
        let models: [String] = ["toy_biplane", "toy_car", "toy_drummer", "toy_robot_vintage"]
        
        var x: Float = -0.3
        
        for (_, name) in models.enumerated(){
            
            let model = try! Entity.load(named: name)
            model.position = [x, -0.4, -0.4]
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(model)
            
            arView.scene.addAnchor(anchor)
            
            for anim in model.availableAnimations{
                model.playAnimation(anim.repeat().repeat(duration: .infinity), transitionDuration: 1.25, startsPaused: false)
            }
            x += 0.2
        }
    }
    
    /**
     Init all 56 cards and pick 16 in a random manure
     */
    func initCards(){
        
        // Cards
        var numbers: [String] = []
        
        for j in 1...4{
            var letter: String
            switch(j){
            case 1:
                letter = "C"
            case 2:
                letter = "H"
            case 3:
                letter = "K"
             default:
                letter = "P"
               
            }
            for i in 2...14{
                let cardNum: String = letter + String(i)
                numbers.append(cardNum)
            }
        }
        
        numbers.shuffle()
        
        // pick cards in a random way
        for i in 0...15{
            values[i] = numbers[i]
        }
        
        // back of cards ("hidden cards")
        for i in 0...15 {
            let box = MeshResource.generateBox(width: 0.026, height: 0.001, depth: 0.039)
            var material = SimpleMaterial()
            
            guard let val = values[i] else{
                break
            }
            
            // open first card
            if i == 0{
                material.color = .init(tint: .white.withAlphaComponent(0.999),
                                       texture: .init(try! .load(named: val)))
                
                // StartingValue
                let range = val.index(after: val.startIndex)..<val.endIndex
                currentVal = Int(val[range]) ?? 0
            }else{
                material.color = .init(tint: .white.withAlphaComponent(0.999),
                                       texture: .init(try! .load(named: "background")))
            }
            
            material.metallic = .float(0.9)
            material.roughness = .float(0.1)
            
            let model = ModelEntity(mesh: box, materials: [material])
            model.generateCollisionShapes(recursive: true)
            model.accessibilityLabel = val
            
            displayedCards.append(model)
            if i == 0{
                openCards.append(model)
            }
        }
        
    }
    
    /**
     Init the scene to start the game
     */
    func initScene(){
        
        // if false -> create "new game" but same positions
        if firstGame == true{
            cardsAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2,0.2])
            firstGame = false
        }
        // add anchor
        arView.scene.addAnchor(cardsAnchor)
        
        // add cards to scene (anchor)
        for (i, card) in displayedCards.enumerated() {
            let position = positions[i]
            card.position = [position.x * 0.05, 0, position.z * 0.05]
            cardsAnchor.addChild(card)
        }
        
        
        // Higher / Lower Buttons
        let box = MeshResource.generatePlane(width: 0.04, depth: 0.03, cornerRadius: 0.1)
        var higherMaterial = SimpleMaterial()
        higherMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                     texture: .init(try! .load(named: "higher")))
        higherMaterial.metallic = .float(0.9) // 1.0
        higherMaterial.roughness = .float(0.1) // 0.0
        let higherModel = ModelEntity(mesh: box, materials: [higherMaterial])
        higherModel.generateCollisionShapes(recursive: true)
        
        var lowerMaterial = SimpleMaterial()
        lowerMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                    texture: .init(try! .load(named: "lower")))
        lowerMaterial.metallic = .float(0.9) // 1.0
        lowerMaterial.roughness = .float(0.1) // 0.0
        
        let lowerModel = ModelEntity(mesh: box, materials: [lowerMaterial])
        lowerModel.generateCollisionShapes(recursive: true)
        
        higherModel.position = [-0.08, 0, 0.04]
        higherModel.accessibilityLabel = "higher"
        lowerModel.position = [-0.08 , 0, 0.08]
        lowerModel.accessibilityLabel = "lower"
        
        buttons.append(higherModel)
        buttons.append(lowerModel)
        cardsAnchor.addChild(higherModel)
        cardsAnchor.addChild(lowerModel)
        
    }
    
    /**
     Repaints the entire scene with all 16 cards
     */
    func repaint(){
                
        // TODO
    }
    
    /**
     If the game ended due to success or failure
     */
    func restartGame(){
        
        // delete cards
        for (i, card) in displayedCards.enumerated(){
            let position = positions[i]
            card.position = [position.x * 0.05, 0, position.z * 0.05]
            cardsAnchor.removeChild(card)
        }
        displayedCards = []
        openCards = []
        
        for (_, button)in buttons.enumerated(){
            cardsAnchor.removeChild(button)
        }
        
        buttons = []
        isAlive = true
        currentRow = 1
        
        initCards()
        initScene()
        
    }
    
    // tap on card handler to decide which button or card has been clicked
    @IBAction func OnTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        if let card = arView.entity(at: tapLocation) {// tap location point
            
            guard let label = card.accessibilityLabel else{
                return
            }
            
            switch (label){
            case "higher":
                if isAlive == false{
                    return
                }
                higherLower = "higher"
                for (_, button)in buttons.enumerated(){
                    cardsAnchor.removeChild(button)
                }
                
                let box = MeshResource.generatePlane(width: 0.04, depth: 0.03, cornerRadius: 0.1)
                var higherMaterial = SimpleMaterial()
                higherMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                             texture: .init(try! .load(named: "higherSelected")))
                higherMaterial.metallic = .float(0.9) // 1.0
                higherMaterial.roughness = .float(0.1) // 0.0
                let higherModel = ModelEntity(mesh: box, materials: [higherMaterial])
                higherModel.generateCollisionShapes(recursive: true)
                
                var lowerMaterial = SimpleMaterial()
                lowerMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                            texture: .init(try! .load(named: "lower")))
                lowerMaterial.metallic = .float(0.9) // 1.0
                lowerMaterial.roughness = .float(0.1) // 0.0
                
                let lowerModel = ModelEntity(mesh: box, materials: [lowerMaterial])
                lowerModel.generateCollisionShapes(recursive: true)
                
                higherModel.position = [-0.08, 0, 0.04]
                higherModel.accessibilityLabel = "higher"
                lowerModel.position = [-0.08 , 0, 0.08]
                lowerModel.accessibilityLabel = "lower"
                
                buttons.append(higherModel)
                buttons.append(lowerModel)
                cardsAnchor.addChild(higherModel)
                cardsAnchor.addChild(lowerModel)
                
            case "lower":
                
                if isAlive == false{
                    return
                }
                higherLower = "lower"
                for (_, button)in buttons.enumerated(){
                    cardsAnchor.removeChild(button)
                }
                
                let box = MeshResource.generatePlane(width: 0.04, depth: 0.03, cornerRadius: 0.1)
                var higherMaterial = SimpleMaterial()
                higherMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                             texture: .init(try! .load(named: "higher")))
                higherMaterial.metallic = .float(0.9) // 1.0
                higherMaterial.roughness = .float(0.1) // 0.0
                let higherModel = ModelEntity(mesh: box, materials: [higherMaterial])
                higherModel.generateCollisionShapes(recursive: true)
                
                var lowerMaterial = SimpleMaterial()
                lowerMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                            texture: .init(try! .load(named: "lowerSelected")))
                lowerMaterial.metallic = .float(0.9) // 1.0
                lowerMaterial.roughness = .float(0.1) // 0.0
                
                let lowerModel = ModelEntity(mesh: box, materials: [lowerMaterial])
                lowerModel.generateCollisionShapes(recursive: true)
                
                higherModel.position = [-0.08, 0, 0.04]
                higherModel.accessibilityLabel = "higher"
                lowerModel.position = [-0.08 , 0, 0.08]
                lowerModel.accessibilityLabel = "lower"
                
                buttons.append(higherModel)
                buttons.append(lowerModel)
                cardsAnchor.addChild(higherModel)
                cardsAnchor.addChild(lowerModel)
                
            case "restart":
                
                restartGame()
               
            case "success":
                restartGame()
            default:
                if (isAlive == true && validRow(label: label) == true){
                    calculateValue(label: label)
                    openCards.append(card)
                    
                    if (openCards.count == 7){ // success
                        let box = MeshResource.generateBox(width: 0.05, height: 0.001, depth: 0.05, splitFaces: false)
                        var restartMaterial = SimpleMaterial()
                        restartMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                                      texture: .init(try! .load(named: "success")))
                        restartMaterial.metallic = .float(0.9) // 1.0
                        restartMaterial.roughness = .float(0.1) // 0.0
                        let restartModel = ModelEntity(mesh: box, materials: [restartMaterial])
                        restartModel.generateCollisionShapes(recursive: true)
                        
                        restartModel.position = [-0.14 , 0, 0.06]
                        restartModel.accessibilityLabel = "success"
                        
                        buttons.append(restartModel)
                        cardsAnchor.addChild(restartModel)
                        isAlive = false
                    }
                }
                
            }
            
        }
        
        repaint()
    }
    
    /**
     Calculate if the selected card is valid (only next in line is allowed)
     */
    func validRow(label: String) -> Bool{
        
        let row: Int
        var count: Int = 0
        
        // loop until we find the card
        for (i, card) in displayedCards.enumerated() {
            let cardLabel = card.accessibilityLabel ?? "default"
            if cardLabel == label{
                count = i
                break
            }
        }
        
        switch (count){
        case 0:
            row = 1
        case 1...2:
            row = 2
        case 3...5:
            row = 3
        case 6...9:
            row = 4
        case 10...12:
            row = 5
        case 13...14:
            row = 6
       default: // 15
            row = 7
        }
                
        if (currentRow + 1 == row){
            currentRow = row
            return true
        }
        return false
    }
    
    /**
     Calculates the value of the card, eg: king = 13, queen = 12, ...
     */
    func calculateValue(label: String){
        let range = label.index(after: label.startIndex)..<label.endIndex
        let val = Int(label[range]) ?? 0 // value of tapped card
        
        if (higherLower == "lower" && val < currentVal){
            currentVal = val
        } else if (higherLower == "higher" && val > currentVal){
            currentVal = val
        } else{
            
            let box = MeshResource.generateBox(width: 0.05, height: 0.001, depth: 0.05, splitFaces: false)
            var restartMaterial = SimpleMaterial()
            restartMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                                          texture: .init(try! .load(named: "restart")))
            restartMaterial.metallic = .float(0.9) // 1.0
            restartMaterial.roughness = .float(0.1) // 0.0
            let restartModel = ModelEntity(mesh: box, materials: [restartMaterial])
            restartModel.generateCollisionShapes(recursive: true)
            
            restartModel.position = [-0.14 , 0, 0.06]
            restartModel.accessibilityLabel = "restart"
            
            buttons.append(restartModel)
            cardsAnchor.addChild(restartModel)
            isAlive = false
            
        }
        
    }
    
    /**
     x, y, z coordinates of cards
     */
    struct position{
        var x: Float
        var y: Float
        var z: Float
        init(_x: Float, _y: Float, _z: Float){
            x = _x
            y = _y
            z = _z
        }
    }
}



 

