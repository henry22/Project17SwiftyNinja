//
//  GameScene.swift
//  Project17SwiftyNinja
//
//  Created by Henry on 6/26/15.
//  Copyright (c) 2015 Henry. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .Replace
        addChild(background)
        
        //the vector arrow is pointing straight down
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        //stay up in the air a bit longer
        physicsWorld.speed = 0.85
        
//        createScore()
//        createLives()
//        createSlices()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}