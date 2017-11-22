//
//  GameScene.swift
//  FlappyBird
//
//  Created by 長谷川勇斗 on 2017/11/21.
//  Copyright © 2017年 長谷川勇斗. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene , SKPhysicsContactDelegate{
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    
    var soundGetItem : AVAudioPlayer! = nil
    var soundScoreUp : AVAudioPlayer! = nil
    
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    var score = 0
    var item = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        let getItemPath = Bundle.main.path(forResource: "itemGet", ofType: "mp3")!
        let soundGetItemURL:URL = URL(fileURLWithPath: getItemPath)
        soundGetItem = try! AVAudioPlayer(contentsOf: soundGetItemURL, fileTypeHint:nil)
        soundGetItem.prepareToPlay()
        
        let scoreUpPath = Bundle.main.path(forResource: "scoreUp", ofType: "mp3")!
        let soundScoreUpURL:URL = URL(fileURLWithPath: scoreUpPath)
        soundScoreUp = try! AVAudioPlayer(contentsOf: soundScoreUpURL, fileTypeHint:nil)
        soundScoreUp.prepareToPlay()
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupItem()
        setupBird()
        setupScoreLabel()
        setupItemLabel()
    }
    
    func setupGround(){
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5.0)
        
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
            sprite.run(repeatScrollGround)
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            sprite.physicsBody?.isDynamic = false
            sprite.physicsBody?.categoryBitMask = groundCategory
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud(){
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)

        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20.0)
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            sprite.run(repeatScrollCloud)
            scrollNode.addChild(sprite)
        }
    }
    
    func setupItem(){
        let itemTexture = SKTexture(imageNamed: "item")
        let wallTexture = SKTexture(imageNamed: "wall")
        let cw = [itemTexture.size().width,wallTexture.size().width].max()
        itemTexture.filteringMode = SKTextureFilteringMode.linear
        
        let movingDistance = CGFloat(self.frame.size.width + cw!)
        let moveItem = SKAction.moveBy(x:-movingDistance, y:0, duration:4.0)
        let removeItem = SKAction.removeFromParent()
        let itemAnimation = SKAction.sequence([moveItem,removeItem])
        
        let createItemAnimation = SKAction.run({
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + cw! / 2, y:0.0)
            item.zPosition = -50.0
            
            let fluit = SKSpriteNode(texture: itemTexture)
            fluit.setScale(0.5)
            fluit.position = CGPoint(x:0.0, y:self.frame.size.height / 2)
            fluit.physicsBody = SKPhysicsBody(texture: fluit.texture!,
                                              size: fluit.texture!.size())
            fluit.physicsBody?.isDynamic = false
            fluit.physicsBody?.categoryBitMask = self.itemCategory
            fluit.physicsBody?.contactTestBitMask = self.birdCategory
            item.addChild(fluit)
            item.run(itemAnimation)
            self.itemNode.addChild(item)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 1)
        //let waitFirstAnimation = SKAction.wait(forDuration: 1)
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation,createItemAnimation,waitAnimation]))
        //self.itemNode.run(waitFirstAnimation)
        self.itemNode.run(repeatForeverAnimation)
    }
    
    func setupWall() {
        let wallTexture = SKTexture(imageNamed: "wall")
        let itemTexture = SKTexture(imageNamed: "item")
        let cw = [itemTexture.size().width,wallTexture.size().width].max()
        wallTexture.filteringMode = SKTextureFilteringMode.linear
        
        let movingDistance = CGFloat(self.frame.size.width + cw!)
        
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        let removeWall = SKAction.removeFromParent()
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + cw! / 2, y: 0.0)
            wall.zPosition = -50.0
            
            let center_y = self.frame.size.height / 2
            let random_y_range = self.frame.size.height / 4
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            let slit_length = self.frame.size.height / 6
            
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.isDynamic = false
            under.physicsBody?.categoryBitMask = self.wallCategory
            wall.addChild(under)
            
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        self.wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.linear
        
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | itemCategory
        bird.run(flap)
        
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            if item == 0 {
                itemLabelNode.text = "Item:0"
            }
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            print("getItem")
            item += 1
            if item == 5 {
                score += 1
                itemLabelNode.text = "Item:0 (Score +1 !!)"
                scoreLabelNode.text = "Score:\(score)"
                soundScoreUp.currentTime = 0
                soundScoreUp.play()
                item = 0
            } else {
                itemLabelNode.text = "Item:\(item)"
                soundGetItem.currentTime = 0
                soundGetItem.play()
            }
            if contact.bodyA.categoryBitMask == itemCategory{
                let deleteNode = SKAction.removeFromParent()
                contact.bodyA.node!.run(deleteNode)
            }
        } else {
            print("GameOver")
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        item = 0
        scoreLabelNode.text = String("Score:\(score)")
        itemLabelNode.text = String("Item:\(item)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    func setupItemLabel(){
        item = 0
        itemLabelNode = SKLabelNode()
        itemLabelNode.fontColor = UIColor.black
        itemLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemLabelNode.zPosition = 100
        itemLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemLabelNode.text = "Item:\(item)"
        self.addChild(itemLabelNode)
    }
    
}
