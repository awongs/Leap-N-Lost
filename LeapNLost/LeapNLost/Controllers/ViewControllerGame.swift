//
//  ViewControllerGame.swift
//  LeapNLost
//
//  Created by Davis Pham on 2019-02-04.
//  Copyright © 2019 bcit. All rights reserved.
//

import Foundation
import GLKit
import Swift

class ViewControllerGame : GLKViewController, GLKViewControllerDelegate {
    
    // The openGL game engine.
    private var gameEngine : GameEngine?;
    
    // This view as a GLKView
    private var glkView : GLKView?;
    
    private var input : InputManager = InputManager.init();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        setupGL();
    }
    
    /**
     * Sets up the openGL engine.
     */
    func setupGL() {
        // Set the context
        glkView = self.view as? GLKView;
        glkView!.context = EAGLContext(api: .openGLES2)!;
        EAGLContext.setCurrent(glkView!.context);
        delegate = self;
        
        // Enable depth buffer
        glkView!.drawableDepthFormat = GLKViewDrawableDepthFormat.format24;
        glEnable(GLbitfield(GL_DEPTH_TEST));
        
        // Start the engine
        gameEngine = GameEngine(self.view as! GLKView);
    }

    
    @IBAction func OnTapGesture(_ sender: UITapGestureRecognizer) {
        if (sender.state == .ended) {
            NSLog("tapped");
        }
    }

    @IBAction func OnSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if (sender.state == .ended) {
            NSLog("Swiped right");
        }
    }
    
    @IBAction func OnSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if (sender.state == .ended) {
            NSLog("Swiped left");
        }
    }
    
    /**
     * Updates the game.
     */
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        input.nextFrame();
        
        gameEngine!.update();
    }
    
    /**
     * Renders the game.
     */
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        gameEngine!.render(rect);
    }
}
