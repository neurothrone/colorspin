//
//  ContentView.swift
//  ColorSpin Watch App
//
//  Created by Zaid Neurothrone on 2022-10-14.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
  @State private var rotation: Double = .zero
  
  @StateObject var scene: GameScene = {
    let scene = GameScene()
    scene.size = CGSize(width: 300, height: 400)
    scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    scene.scaleMode = .resizeFill
    return scene
  }()
  
  private let oneBillion: Double = 1_000_000_000
  
  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Score \(scene.score)")
        .navigationBarTitleDisplayMode(.inline)
    }
  }
  
  var content: some View {
    SpriteView(scene: scene)
      .ignoresSafeArea()
      .focusable()
      .digitalCrownRotation(
        $rotation,
        from: -oneBillion,
        through: oneBillion,
        sensitivity: .low,
        isContinuous: true)
      .onChange(of: rotation) { _ in
        scene.rotate(to: rotation)
      }
      .onTapGesture(perform: scene.reset)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
