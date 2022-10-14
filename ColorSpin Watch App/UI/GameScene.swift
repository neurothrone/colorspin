//
//  GameScene.swift
//  ColorSpin Watch App
//
//  Created by Zaid Neurothrone on 2022-10-14.
//

import SpriteKit
import WatchKit

final class GameScene: SKScene, ObservableObject {
  @Published var score: Int = .zero
  
  let player = SKNode()
  
  let leftEdge = SKSpriteNode(color: .white, size: .init(width: 10, height: 150))
  let rightEdge = SKSpriteNode(color: .white, size: .init(width: 10, height: 150))
  let topEdge = SKSpriteNode(color: .white, size: .init(width: 150, height: 10))
  let bottomEdge = SKSpriteNode(color: .white, size: .init(width: 150, height: 10))
  
  let colorNames = ["Red", "Blue", "Green", "Yellow"]
  let colorValues: [UIColor] = [.red, .blue, .green, .yellow]
  
  var isPlayerAlive = true
  var createDelay = 0.5
  var alertDelay = 1.0
  var moveSpeed = 70.0
  
  func createPlayer(color: String) -> SKSpriteNode {
    let component = SKSpriteNode(imageNamed: "player\(color)")
    component.physicsBody = SKPhysicsBody(texture: component.texture!, size: component.size)
    component.physicsBody?.isDynamic = false
    component.name = color
    player.addChild(component)
    return component
  }
  
  func setUp() {
    backgroundColor = .black
    physicsWorld.contactDelegate = self
    
    let colorToPositions: [String: (x: Int, y: Int)] = [
      "Red": (x: -8, y: 8),
      "Blue": (x: 8, y: 8),
      "Green": (x: -8, y: -8),
      "Yellow": (x: 8, y: -8),
    ]
    
    colorToPositions.forEach { color, position in
      let node = createPlayer(color: color)
      node.position = CGPoint(x: position.x, y: position.y)
    }
    
    addChild(player)
    
    leftEdge.position = CGPoint(x: -50, y: .zero)
    rightEdge.position = CGPoint(x: 50, y: .zero)
    topEdge.position = CGPoint(x: .zero, y: 50)
    bottomEdge.position = CGPoint(x: .zero, y: -50)
    
    for edge in [leftEdge, rightEdge, topEdge, bottomEdge] {
      edge.colorBlendFactor = 1
      edge.alpha = .zero
      addChild(edge)
    }
    
    Task { @MainActor in
      try await Task.sleep(until: .now + .milliseconds(createDelay), clock: .continuous)
      self.launchBall()
    }
  }
  
  func rotate(to newRotation: Double) {
    player.zRotation = newRotation
  }
  
  func pickEdge() -> (position: CGPoint, force: CGVector, edge: SKSpriteNode) {
    let direction = Int.random(in: 0...3)
    
    switch direction {
    case 0:
      return (
        CGPoint(x: -110, y: .zero),
        CGVector(dx: moveSpeed, dy: .zero),
        leftEdge
      )
    case 1:
      return (
        CGPoint(x: 110, y: .zero),
        CGVector(dx: -moveSpeed, dy: .zero),
        rightEdge
      )
    case 2:
      return (
        CGPoint(x: .zero, y: -120),
        CGVector(dx: .zero, dy: moveSpeed),
        bottomEdge
      )
    default:
      return (
        CGPoint(x: .zero, y: 120),
        CGVector(dx: .zero, dy: -moveSpeed),
        topEdge
      )
    }
  }
  
  func createBall(color: String) -> SKSpriteNode {
    let ball = SKSpriteNode(imageNamed: "ball\(color)")
    ball.name = color
    
    ball.physicsBody = SKPhysicsBody(circleOfRadius: 12)
    ball.physicsBody?.linearDamping = .zero
    ball.physicsBody?.affectedByGravity = false
    ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? .zero
    
    addChild(ball)
    return ball
  }
  
  func launchBall() {
    guard isPlayerAlive else { return }
    
    let ballType = Int.random(in: colorNames.indices)
    let ball = createBall(color: colorNames[ballType])
    
    let (position, force, edge) = pickEdge()
    ball.position = position
    
    let flashEdge = SKAction.run {
      edge.color = self.colorValues[ballType]
      edge.alpha = 1
    }
    
    let resetEdge = SKAction.run {
      edge.alpha = .zero
    }
    
    let launchBall = SKAction.run {
      ball.physicsBody!.velocity = force
    }
    
    let sequence = SKAction.sequence([
      flashEdge,
      SKAction.wait(forDuration: alertDelay),
      resetEdge,
      launchBall
    ])
    
    run(sequence)
    alertDelay *= 0.98
  }
  
  override func didChangeSize(_ oldSize: CGSize) {
    guard size.width > 100 else { return }
    guard player.children.isEmpty else { return }
    
    setUp()
  }
}

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    guard let nodeA = contact.bodyA.node else { return }
    guard let nodeB = contact.bodyB.node else { return }
    
    if nodeA.parent == self {
      ball(nodeA, hit: nodeB)
    } else if nodeB.parent == self {
      ball(nodeB, hit: nodeA)
    } else {
      // Neither? Just exit!
      return
    }
    
    Task { @MainActor in
      try await Task.sleep(until: .now + .milliseconds(createDelay), clock: .continuous)
      self.launchBall()
    }
  }
  
  func ball(_ ball: SKNode, hit color: SKNode) {
    guard isPlayerAlive else { return }
    
    ball.removeFromParent()
    
    if ball.name == color.name {
      score += 1
    } else {
      // Game over
      isPlayerAlive = false
      let gameOver = SKSpriteNode(imageNamed: "gameOver")
      gameOver.xScale = 2.0
      gameOver.yScale = 2.0
      gameOver.alpha = .zero
      addChild(gameOver)
      
      let fadeIn = SKAction.fadeIn(withDuration: 0.5)
      let scaleDown = SKAction.scale(to: 1, duration: 0.5)
      let group = SKAction.group([fadeIn, scaleDown])
      gameOver.run(group)
    }
  }
  
  func reset() {
    guard !isPlayerAlive else { return }
    
    removeAllChildren()
    isPlayerAlive = true
    score = 0
    
    setUp()
  }
}
