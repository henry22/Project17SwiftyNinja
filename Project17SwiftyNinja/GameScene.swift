//
//  GameScene.swift
//  Project17SwiftyNinja
//
//  Created by Henry on 6/26/15.
//  Copyright (c) 2015 Henry. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    var gameScore: SKLabelNode!
    var score: Int = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    var livesImage = [SKSpriteNode]()
    var lives = 3
    
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    
    var activeSlicePoints = [CGPoint]()
    
    var swooshSoundActive = false
    
    enum ForceBomb {
        case Never, Always, Default
    }
    
    var bombSoundEffect: AVAudioPlayer!
    
    //track enemies that are currently active in the scene
    var activeEnemies = [SKSpriteNode]()
    
    enum SequenceType: Int {
        case OneNoBomb, One, TwoWithOneBomb, Two, Three, Four, Chain, FastChain
    }
    
    //wait between the last enemy being destroyed and a new one being created
    var popTime = 0.9
    //defines what enemies to create
    var sequence: [SequenceType]!
    //where we are right now in the game
    var sequencePosition = 0
    //how long to wait before creating a new enemy when the sequence type is .Chain or .FastChain
    var chainDelay = 3.0
    //we know when all the enemies are destroyed and we're ready to create more
    var nextSequenceQueued = true
    
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .Replace
        addChild(background)
        
        //the vector arrow is pointing straight down
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        //stay up in the air a bit longer
        physicsWorld.speed = 0.85
        
        createScore()
        createLives()
        createSlices()
        
        //help players warm up to how the game works
        sequence = [.OneNoBomb, .OneNoBomb, .TwoWithOneBomb, .TwoWithOneBomb, .Three, .One, .Chain]
        
        for i in 0 ... 1000 {
            var nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 7))!
            sequence.append(nextSequence)
        }
        
        //triggers the initial enemy toss after two seconds
        runAfterDelay(2) { [unowned self] in
            self.tossEnemies()
        }
    }
    
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .Left
        gameScore.fontSize = 48
        
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
    }
    
    func createLives() {
        for i in 0..<3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            
            livesImage.append(spriteNode)
        }
    }
    
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        
        //yellow glow
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor.whiteColor()
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        //finding a touch within the set
        let touch = touches.first as! UITouch
        let location = touch.locationInNode(self)
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !swooshSoundActive {
            playSwooshSound()
        }
        
        let nodes = nodesAtPoint(location) as! [SKNode]
        
        for node in nodes {
            if node.name == "enemy" {
                //destroy penguin
                
                //Create a particle effect over the penguin
                let explosivePath = NSBundle.mainBundle().pathForResource("sliceHitEnemy", ofType: "sks")!
                let emitter = NSKeyedUnarchiver.unarchiveObjectWithFile(explosivePath) as! SKEmitterNode
                emitter.position = node.position
                addChild(emitter)
                
                //Clear its node name so that it can't be swiped repeatedly
                node.name = ""
                
                //Disable the dynamic of its physics body so that it doesn't carry on falling
                node.physicsBody!.dynamic = false
                
                //Make the penguin scale out and fade out at the same time
                let scaleOut = SKAction.scaleTo(0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOutWithDuration(0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                //After making the penguin scale out and fade out, we should remove it from the scene
                let seq = SKAction.sequence([group, SKAction.removeFromParent()])
                node.runAction(seq)
                
                //Add one to the player's score
                ++score
                
                //Remove the enemy from our activeEnemies array
                let index = find(activeEnemies, node as! SKSpriteNode)
                activeEnemies.removeAtIndex(index!)
                
                //Play a sound so the player knows they hit the penguin
                runAction(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
                
            } else if node.name == "bomb" {
                //destroy bomb
                
                let explosionPath = NSBundle.mainBundle().pathForResource("sliceHitBomb", ofType: "sks")
                let emitter = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath!) as! SKEmitterNode
                emitter.position = node.parent!.position
                addChild(emitter)
                
                node.name = ""
                node.parent!.physicsBody!.dynamic = false
                
                let scaleOut = SKAction.scaleTo(0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOutWithDuration(0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, SKAction.removeFromParent()])
                
                node.parent!.runAction(seq)
                
                let index = find(activeEnemies, node.parent as! SKSpriteNode)!
                activeEnemies.removeAtIndex(index)
                
                runAction(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
//                endGame(triggeredByBomb: true)
            }
        }
    }
    
    func playSwooshSound() {
        //no other swoosh sounds are played until we're ready
        swooshSoundActive = true
        
        var randomNumber = RandomInt(min: 1, max: 3)
        var soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        //when the sound has finished set swooshSoundActive to be false again so that another swoosh sound can play
        runAction(swooshSound) { [unowned self] in
            self.swooshSoundActive = false
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        activeSliceBG.runAction(SKAction.fadeOutWithDuration(0.25))
        activeSliceFG.runAction(SKAction.fadeOutWithDuration(0.25))
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        touchesEnded(touches, withEvent: event)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        //Remove all existing points in the activeSlicePoints array, because starting fresh
        activeSlicePoints.removeAll(keepCapacity: true)
        
        //Get the touch location and add it to the activeSlicePoints array
        let touch = touches.first as! UITouch
        let location = touch.locationInNode(self)
        activeSlicePoints.append(location)
        
        //Call the redrawActiveSlice() method to clear the slice shapes
        redrawActiveSlice()
        
        //Remove any actions that are currently attached to the slice shapes
        activeSliceBG.removeAllActions()
        activeSliceFG.removeAllActions()
        
        //Set both slice shapes to have an alpha value of 1 so they are fully visible
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1
    }
    
    func redrawActiveSlice() {
        //If we have fewer than two points in our array, we don't have enough data to draw a line so it needs to clear the shapes and exit the method
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        //If we have more than 12 slice points in our array, we need to remove the oldest ones until we have at most 12 – this stops the swipe shapes from becoming too long
        while activeSlicePoints.count > 12 {
            activeSlicePoints.removeAtIndex(0)
        }
        
        //It needs to start its line at the position of the first swipe point, then go through each of the others drawing lines to each point
        var path = UIBezierPath()
        path.moveToPoint(activeSlicePoints[0])
        
        for var i = 1; i < activeSlicePoints.count; ++i {
            path.addLineToPoint(activeSlicePoints[i])
        }
        
        //It needs to update the slice shape paths so they get drawn using their designs
        activeSliceBG.path = path.CGPath
        activeSliceFG.path = path.CGPath
    }
    
    func createEnemy(forceBomb: ForceBomb = .Default) {
        var enemy: SKSpriteNode
        
        var enemyType = RandomInt(min: 0, max: 6)
        
        if forceBomb == .Never {
            enemyType = 1
        } else if forceBomb == .Always {
            enemyType = 0
        }
        
        if enemyType == 0 {
            //bomb code goes here
            
            //Create a new SKSpriteNode that will hold the fuse and the bomb image as children
            enemy = SKSpriteNode()
            //bombs always appear in front of penguins
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            //Create the bomb image, name it "bomb", and add it to the container
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            //If the bomb fuse sound effect is playing, stop it and destroy it
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
            
            //Create a new bomb fuse sound effect, then play it
            let path = NSBundle.mainBundle().pathForResource("sliceBombFuse.caf", ofType: nil)!
            let url = NSURL(fileURLWithPath: path)
            let sound = AVAudioPlayer(contentsOfURL: url, error: nil)
            bombSoundEffect = sound
            sound.play()
            
            //Create a particle emitter node, position it so that it's at the end of the bomb image's fuse, and add it to the container
            let particlePath = NSBundle.mainBundle().pathForResource("sliceFuse", ofType: "sks")!
            let emitter = NSKeyedUnarchiver.unarchiveObjectWithFile(particlePath) as! SKEmitterNode
            emitter.position = CGPoint(x: 76, y: 64)
            enemy.addChild(emitter)
            
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            runAction(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }

        //Give the enemy a random position off the bottom edge of the screen
        let randomPosition = CGPoint(x: RandomInt(min: 64, max: 960), y: -128)
        enemy.position = randomPosition
        
        //Create a random angular velocity, which is how fast something should spin
        let randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6)) / 2.0
        var randomXVelocity = 0
        
        //Create a random X velocity (how far to move horizontally) that takes into account the enemy's position
        if randomPosition.x < 256 {
            randomXVelocity = RandomInt(min: 8, max: 15)
        } else if randomPosition.x < 512 {
            randomXVelocity = RandomInt(min: 3, max: 5)
        } else if randomPosition.x < 768 {
            randomXVelocity = -RandomInt(min: 3, max: 5)
        } else {
            randomXVelocity = -RandomInt(min: 8, max: 15)
        }
        
        //Create a random Y velocity just to make things fly at different speeds
        let randomYVelocity = RandomInt(min: 24, max: 32)
        
        //Give all enemies a circular physics body where the collisionBitMask is set to 0 so they don't collide
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody!.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody!.angularVelocity = randomAngularVelocity
        enemy.physicsBody!.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
   
    override func update(currentTime: CFTimeInterval) {
        
        if activeEnemies.count > 0 {
            for node in activeEnemies {
                if node.position.y < -140 {
                    node.removeFromParent()
                    
                    if node.name == "enemy" {
                        node.name = ""
//                        subtractLife()
                        
                        node.removeFromParent()
                        
                        if let index = find(activeEnemies, node) {
                            activeEnemies.removeAtIndex(index)
                        }
                    } else if node.name == "bombContainer" {
                        node.name = ""
                        node.removeFromParent()
                        
                        if let index = find(activeEnemies, node) {
                            activeEnemies.removeAtIndex(index)
                        }
                    }
                }
            }
        } else {
            if !nextSequenceQueued {
                runAfterDelay(popTime) { [unowned self] in
                    self.tossEnemies()
                }
            }
            
            nextSequenceQueued = true
        }
        
        var bombCount = 0
        
        for node in activeEnemies {
            //count the number of bomb containers that exist in game
            if node.name == "bombContainer" {
                ++bombCount
                break
            }
        }
        
        if bombCount == 0 {
            // no bombs – stop the fuse sound
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
        }
    }
    
    func tossEnemies() {
        popTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .OneNoBomb:
            createEnemy(forceBomb: .Never)
            
        case .One:
            createEnemy()
            
        case .TwoWithOneBomb:
            createEnemy(forceBomb: .Never)
            createEnemy(forceBomb: .Always)
            
        case .Two:
            createEnemy()
            createEnemy()
            
        case .Three:
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .Four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .Chain:
            createEnemy()
            
            runAfterDelay(chainDelay / 5.0) { [unowned self] in self.createEnemy() }
            runAfterDelay(chainDelay / 5.0 * 2) { [unowned self] in self.createEnemy() }
            runAfterDelay(chainDelay / 5.0 * 3) { [unowned self] in self.createEnemy() }
            runAfterDelay(chainDelay / 5.0 * 4) { [unowned self] in self.createEnemy() }
            
        case .FastChain:
            createEnemy()
            
            runAfterDelay(chainDelay / 10.0) { [unowned self] in self.createEnemy() }
            runAfterDelay(chainDelay / 10.0 * 2) { [unowned self] in self.createEnemy() }
            runAfterDelay(chainDelay / 10.0 * 3) { [unowned self] in self.createEnemy() }
            runAfterDelay(chainDelay / 10.0 * 4) { [unowned self] in self.createEnemy() }
        }
        
        ++sequencePosition
        
        //we don't have a call to tossEnemies() in the pipeline waiting to execute
        nextSequenceQueued = false
    }
}
