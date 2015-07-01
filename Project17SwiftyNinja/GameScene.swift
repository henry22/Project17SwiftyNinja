//
//  GameScene.swift
//  Project17SwiftyNinja
//
//  Created by Henry on 6/26/15.
//  Copyright (c) 2015 Henry. All rights reserved.
//

import SpriteKit

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
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
