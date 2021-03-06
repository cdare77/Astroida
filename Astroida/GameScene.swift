//
//  GameScene.swift
//  Astroida
//
//  Created by Chris Dare on 10/17/15.
//  Copyright (c) 2015 Chris Dare. All rights reserved.
//

import SpriteKit
import CoreMotion

enum SequenceType: Int {
    case One, Two, Three, Four, Chain, Five, Six, Seven, HeavyChain
}

let criticism = ["Sir, have you been drinking tonight?", "Who the hell taught you to fly.", "I've seen old Vulcan women fly better than that", "Don't worry, it's five star safety rating", "\"If you ain't first, you're last\" - Ricky Bobby", "I think Razor scooters are more your thing", "Shake and Bake?", "Mediocrity like that takes effort", "...With the coordination of an epileptic", "I would sigh if my developer imlemented me so"]

let kScore = "score"
var highScore = 0

class GameScene: SKScene {
    var scoreLabel: SKLabelNode!
    var score: Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    var emitterNode: SKEmitterNode!
    var activeSliceFG: SKShapeNode!
    var activeSliceBG: SKShapeNode!
    var activeSlicePoints = [CGPoint]()
    var liveAsteroids = [SKSpriteNode]()
    var liveTimer = 2.0
    var respawnTimer = 2.0
    var gameEnded = false
    var ship: SKSpriteNode!
    var sequence: [SequenceType]!
    var seqPosition = 0
    var nextSequencedQueue = true
    var asteroidSize: CGSize = SKSpriteNode(imageNamed: "asteroid").size
    var highscoreLabel: SKLabelNode!
    var restartButton: SKLabelNode!

    var gameOverLabel: SKLabelNode!
    var criticismLabel: SKLabelNode!
    var blowUp: SKEmitterNode!
    var motionManager: CMMotionManager!
    var motionQueue: NSOperationQueue!
    var pauseButton: SKLabelNode!
    

    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */

        createScore()
        createHighScoreLabel()
        createPauseButton()
        createRestartButton()
        createGameOverLabel()
        createCriticismLabel()
        
        motionQueue = NSOperationQueue()
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.1

        
        blowUp = SKEmitterNode(fileNamed: "MyParticle3")
        blowUp!.zPosition = 5
        
        start(view)
    }
    
    func updateViewWithMotion(accelData: CMAccelerometerData)
    {
        let dx = 100.0 * accelData.acceleration.y
        let dy = 25.0 - 60.0 * accelData.acceleration.x
        var newX = ship.position.x + CGFloat(dx)
        var newY = ship.position.y + CGFloat(dy)
        
        if newX < 0 {
            newX = 0
        }
        else if newX > view!.frame.size.width {
            newX = view!.frame.size.width
        }
        if newY < 0 {
            newY = 0
        }
        else if newY > view!.frame.size.height {
            newY = view!.frame.size.height
        }
        
        ship.runAction(SKAction.moveTo(CGPoint(x: newX, y: newY), duration: 0.2))
        //ship.runAction(SKAction.moveBy(CGVector(dx: dx, dy: dy), duration: 0.2))
        ship.runAction(SKAction.rotateToAngle(CGFloat(-2 * accelData.acceleration.y), duration: 0.5))
    }
    
    func start(view: SKView)  {
        size = view.bounds.size
        load()
        score = 0
        
        motionManager.startAccelerometerUpdatesToQueue(motionQueue) { (accelData, error) -> Void in
            self.updateViewWithMotion(accelData!)
        }
        
        let background = SKSpriteNode(imageNamed: "starfield")
        background.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        background.blendMode = .Replace
        background.zPosition = -1
        
        addChild(background)
        
        ship = SKSpriteNode(imageNamed: "spaceship")
        ship.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        ship.zPosition = 3
        
        addChild(ship)
        
        criticismLabel.text = criticism[RandomInt(min: 0, max: criticism.count - 1)]
        
        createEmitterNode()
        createSlices()

        highscoreLabel.text = "High Score: \(highScore)"
        
        sequence = [.One, .One, .Two, .Two, .Two, .Three, .Three, .Three, .Chain, .Chain, .Four, .Five, .Six, .Seven, .HeavyChain]
        
        for _ in 0...1500 {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 3, max: 8))!
            sequence.append(nextSequence)
        }
        gameOverLabel.hidden = false
        gameOverLabel.text = "3"
        
        RunAfterDelay(1) { [unowned self] in
            self.gameOverLabel.text = "2"
            self.gameOverLabel.runAction(SKAction.scaleTo(3.0, duration: 1.0))
        }
        RunAfterDelay(2) { [unowned self] in
            self.gameOverLabel.text = "1"
            self.gameOverLabel.runAction(SKAction.scaleTo(3.0, duration: 1.0))
        }
        RunAfterDelay(3) { [unowned self] in
            self.gameOverLabel.hidden = true
            self.gameOverLabel.text = "GAME OVER"
            self.startAsteroids()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        if let touch = touches.first {
            let location = touch.locationInNode(self)
            let nodesAtPos = nodesAtPoint(location)
            
            if nodesAtPos.contains(pauseButton) {
                self.scene!.view!.paused = !(self.scene!.view!.paused)
            }
            
            if gameEnded {
                if nodesAtPos.contains(restartButton) {
                    restartButton.runAction(SKAction.scaleTo(0.5, duration: 0.2))
                    gameEnded = false
                    restartButton.hidden = true
                    gameOverLabel.hidden = true
                    criticismLabel.hidden = true
                    
                    for _ in 0...1500 {
                        let nextSequence = SequenceType(rawValue: RandomInt(min: 3, max: 8))!
                        sequence.append(nextSequence)
                    }
                    
                    blowUp.removeFromParent()
                    activeSliceBG.removeFromParent()
                    activeSliceFG.removeFromParent()
                    
                    scoreLabel.text = "Score: 0"
                    
                    start(scene!.view!)
                    return
                }
            } else {
                super.touchesBegan(touches, withEvent: event)
        
                activeSlicePoints.removeAll(keepCapacity: true)
        

                activeSlicePoints.append(location)
            
                redrawActiveSlice()
            
                activeSliceFG.removeAllActions()
                activeSliceBG.removeAllActions()
            
                activeSliceBG.alpha = 1
                activeSliceFG.alpha = 1
            
            }
        }
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if gameEnded {
            return
        }
        
        for asteroid in liveAsteroids {
            if asteroid.size.width >= 1.7 * asteroidSize.width {
                if ship.position.x + (ship.size.width / 2) > asteroid.position.x - (asteroid.size.width / 6) && ship.position.x - (ship.size.width  / 2) < asteroid.position.x + (asteroid.size.width / 6) {
                    if ship.position.y + (ship.size.height / 2) > asteroid.position.y - (asteroid.size.height / 6) && ship.position.y - (ship.size.height  / 2) < asteroid.position.y + (asteroid.size.width / 6) {
                        gameOver()
                        return
                    }
                }
            }
        }
        
        if !nextSequencedQueue {
            RunAfterDelay(respawnTimer) { [unowned self] in
                self.startAsteroids()
            }
            
            nextSequencedQueue = true
        }
        score += 1
    }
    
    func RunAfterDelay(delay: NSTimeInterval, block: dispatch_block_t) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), block)
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Copperplate")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .Left
        scoreLabel.fontSize = 32
        
        addChild(scoreLabel)
    }
    func createPauseButton() {
        pauseButton = SKLabelNode(text: "| |")
        pauseButton.fontName = "AvenirNext-Heavy"
        pauseButton.fontSize = 25
        pauseButton.position = CGPoint(x: 15, y: view!.frame.height - 35.0)
        addChild(pauseButton)
    }
    func createRestartButton() {
        restartButton = SKLabelNode(text: "Restart")
        restartButton.fontName = "Copperplate"
        restartButton.fontSize = 50
        restartButton.fontColor = UIColor(red: 196.0/255, green: 0.0, blue: 193.0/255, alpha: 1.0)
        restartButton.hidden = true
        restartButton.position = CGPoint(x: view!.frame.width / 2, y: view!.frame.height / 2 - 80.0)
        addChild(restartButton)
    }
    func createHighScoreLabel() {
        highscoreLabel = SKLabelNode(fontNamed: "Copperplate")
        highscoreLabel.text = "High Score: 0"
        highscoreLabel.horizontalAlignmentMode = .Left
        highscoreLabel.position = CGPoint(x: view!.frame.width - 225, y: 0)
        highscoreLabel.fontSize = 24
        
        addChild(highscoreLabel)
    }
    func createEmitterNode() {
        emitterNode = SKEmitterNode(fileNamed: "MyParticle2")
        emitterNode.position = CGPoint(x: view!.frame.width / 2, y: view!.frame.height / 2)
        
        addChild(emitterNode)
    }
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        
        activeSliceBG.strokeColor = UIColor(red: 218.0/255, green: 12.0/255, blue: 245.0/255, alpha: 1.0)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor(red: 48.0/255, green: 19.0/255, blue: 99.0/255, alpha: 1.0)
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    func createGameOverLabel() {
        gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.zPosition = 2
        gameOverLabel.fontName = "Copperplate"
        gameOverLabel.hidden = true
        gameOverLabel.position = CGPoint(x: view!.frame.width / 2, y: view!.frame.height / 2 + 50.0)
        addChild(gameOverLabel)
    }
    func createCriticismLabel() {
        criticismLabel = SKLabelNode(fontNamed: "Copperplate")
        criticismLabel.zPosition = 2
        criticismLabel.position = CGPoint(x: view!.frame.width / 2, y: view!.frame.height / 2 - 10.0)
        criticismLabel.fontSize = 20
        criticismLabel.hidden = true
        criticismLabel.text = criticism[RandomInt(min: 0, max: criticism.count - 1)]
        addChild(criticismLabel)
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameEnded {
            return
        }
        
        activeSliceBG.runAction(SKAction.fadeOutWithDuration(0.25))
        activeSliceFG.runAction(SKAction.fadeOutWithDuration(0.25))
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameEnded {
            return
        }
        
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.locationInNode(self)
        let node = nodeAtPoint(location)
        if node.name == "asteroid" {
            let smokeEmitter = SKEmitterNode(fileNamed: "MyParticle")
            smokeEmitter!.position = node.position
            addChild(smokeEmitter!)
                
            RunAfterDelay(0.9) {
                smokeEmitter!.removeFromParent()
            }
                
            node.removeFromParent()
            /*if let _ = scoreLabel {
                score -= 100
            }*/
        }
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
    
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if gameEnded {
            return
        }
        touchesEnded(touches!, withEvent: event)
    }
    
    func redrawActiveSlice() {
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        while activeSlicePoints.count > 9 {
            activeSlicePoints.removeAtIndex(0)
        }
        
        let path = UIBezierPath()
        path.moveToPoint(activeSlicePoints[0])
        
        for var i = 1; i < activeSlicePoints.count; ++i {
            path.addLineToPoint(activeSlicePoints[i])
        }
        
        activeSliceBG.path = path.CGPath
        activeSliceFG.path = path.CGPath
    }
    
    func createAsteroid() {
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        
        let xPos = RandomInt(min: 64, max: Int(view!.frame.width) - 64)
        let yPos = RandomInt(min: 64, max: Int(view!.frame.height) - 64)
        
        asteroid.size = CGSize(width: asteroid.size.width / 4, height: asteroid.size.height / 4)
        asteroid.position = CGPoint(x: xPos, y: yPos)
        asteroid.name = "asteroid"
        asteroid.zPosition = 2
        asteroid.runAction(SKAction.scaleBy(8.0, duration: liveTimer))
        
        liveAsteroids.append(asteroid)
        addChild(asteroid)
        
        RunAfterDelay(liveTimer) { [unowned self] in
            self.liveAsteroids.removeAtIndex(self.liveAsteroids.indexOf(asteroid)!)
            asteroid.removeFromParent()
        }
        
    }
    func RandomInt(min min: Int, max: Int) -> Int {
        if max < min { return min }
        return Int(arc4random_uniform(UInt32((max - min) + 1))) + min
    }
    
    func startAsteroids() {
        if gameEnded {
            return
        }
        
        respawnTimer *= 0.991
        
        let seq = sequence[seqPosition]
        
        switch seq {
        case .One:
            createAsteroid()
        case .Two:
            createAsteroid()
            createAsteroid()
        case .Three:
            createAsteroid()
            createAsteroid()
            createAsteroid()
        case .Four:
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
        case .Chain:
            RunAfterDelay(respawnTimer / 10.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 2.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 3.0) { [unowned self] in
                self.createAsteroid()
            }
        case .Five:
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
        case .Six:
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
        case .Seven:
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
            createAsteroid()
        case .HeavyChain:
            RunAfterDelay(respawnTimer / 10.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 2.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 3.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 4.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 5.0) { [unowned self] in
                self.createAsteroid()
            }
            RunAfterDelay(respawnTimer / 10.0 * 5.0) { [unowned self] in
                self.createAsteroid()
            }
        }
        
        ++seqPosition
        nextSequencedQueue = false
    }
    
    func gameOver() {
        if gameEnded {
            return
        }
        
        motionManager.stopAccelerometerUpdates()
        
        restartButton.hidden = false
        gameOverLabel.hidden = false
        criticismLabel.hidden = false
        
        gameEnded = true
        
        emitterNode.removeFromParent()
        
        for asteroid in liveAsteroids {
            asteroid.removeFromParent()
        }
        
        sequence.removeAll(keepCapacity: true)
        
        activeSliceBG.removeFromParent()
        activeSliceFG.removeFromParent()

        blowUp!.position = ship.position
        addChild(blowUp!)
        ship.removeFromParent()
        
        if score > highScore {
            highScore = score
            save()
            highscoreLabel.text = "High Score: \(score)"
        }
        
    }
    
    func save() {
        NSUserDefaults.standardUserDefaults().setInteger(highScore, forKey: kScore)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    func load() {
        let loadedData = NSUserDefaults.standardUserDefaults().integerForKey(kScore)
        if loadedData != 0 {
            highScore = loadedData
        }
    }
}
