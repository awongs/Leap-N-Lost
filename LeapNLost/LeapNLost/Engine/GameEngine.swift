//
//  GameEngine.swift
//  LeapNLost
//
//  Created by Anthony Wong on 2019-02-06.
//  Copyright © 2019 bcit. All rights reserved.
//

import Foundation
import GLKit

/**
 * Class for the game engine.
 * Renders and updates all game objects every frame.
 */
class GameEngine {
    
    // Reference to the game view.
    private var view : GLKView;
    
    // Reference to the shader
    private var shader : Shader;
    
    // Array of all game objects in the scene.
    var gameObjects : [GameObject];
    
    // The directional light in the scene, i.e. the sun
    var directionalLight : DirectionalLight;
    
    // Arrays of all lights in the scene.
    var pointLights : [PointLight];
    //var spotlights : [Spotlight];
    
    // Camera properties
    var mainCamera : Camera;
    
    /**
     * Constructor for the game engine.
     * view - Reference to the application view.
     */
    init(_ view : GLKView) {
        // Initialize properties
        self.view = view;
        
        // Load shaders
        let programHandle : GLuint = ShaderLoader().compile(vertexShader: "VertexShader.glsl", fragmentShader: "FragmentShader.glsl");
        self.shader = Shader(programHandle: programHandle);
        
        // Populate with gameobjects for testing purposes
        gameObjects = [GameObject]();
        for _ in 1...10 {
            gameObjects.append(GameObject(Model.CreatePrimitive(primitiveType: Model.Primitive.Cube)));
        }
        
        // Initialize some test lighting
        pointLights = [PointLight]();
        for _ in 0...3 {
            pointLights.append(PointLight(color: Vector3(1, 0, 0.5), ambientIntensity: 0.5, diffuseIntensity: 1, specularIntensity: 1, position: Vector3(0, 0, 0), constant: 1.0, linear: 0.5, quadratic: 0.1));
        }
        directionalLight = DirectionalLight(color: Vector3(1, 1, 0.8), ambientIntensity: 0.5, diffuseIntensity: 1, specularIntensity: 1, direction: Vector3(0, -1, -1));
        
        // Setup the camera
        mainCamera = Camera();
        mainCamera.setPosition(xPosition: 0, yPosition: 0, zPosition: -10);
    }
    
    /**
     * The update loop.
     */
    func update() {
        // Create a projection matrix
        mainCamera.calculatePerspectiveMatrix(viewWidth: view.drawableWidth, viewHeight: view.drawableHeight, fieldOfView: 60, nearClipZ: 1, farClipZ: 20);
        
        // Loop through every object in scene and call update
        for gameObject in gameObjects {
            gameObject.update();
        }
    }
    
    /**
     * The render loop.
     */
    func render(_ draw : CGRect) {
        // Clear screen and buffers
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        // Set camera position variable in shader
        shader.setVector(variableName: "view_Position", value: Vector3(0, 0, -10));
        
        // Loop through every object in scene and call render
        for gameObject in gameObjects {
            
            // Get the game object's rotation as a matrix
            var rotationMatrix : GLKMatrix4 = GLKMatrix4RotateX(GLKMatrix4Identity, gameObject.rotation.x);
            rotationMatrix = GLKMatrix4RotateY(rotationMatrix, gameObject.rotation.y);
            rotationMatrix = GLKMatrix4RotateY(rotationMatrix, gameObject.rotation.z);
            
            // Get the game object's position as a matrix
            let positionMatrix : GLKMatrix4 = GLKMatrix4Translate(GLKMatrix4Identity, gameObject.position.x, gameObject.position.y, gameObject.position.z);
            
            // Multiply together to get transformation matrix
            var objectMatrix : GLKMatrix4 = GLKMatrix4Multiply(mainCamera.transformMatrix, positionMatrix);
            objectMatrix = GLKMatrix4Multiply(objectMatrix, rotationMatrix);
            objectMatrix = GLKMatrix4Scale(objectMatrix, gameObject.scale.x, gameObject.scale.y, gameObject.scale.z); // Scaling
            
            // Apply all point lights to the rendering of this game object
            // TODO - Only apply point lights that are within range
            var lightsRendered : Int = 0;
            
            for light in pointLights {
                light.render(shader: shader, lightNumber: lightsRendered);
                lightsRendered += 1;
                
                // Stop after maximum number of lights
                if (lightsRendered == 4) {
                    break;
                }
            }
            
            directionalLight.render(shader: shader);
            
            // Render the object after passing the matrices and texture to the shader
            shader.setMatrix(variableName: "u_ModelViewMatrix", value: objectMatrix);
            shader.setMatrix(variableName: "u_ProjectionMatrix", value: mainCamera.perspectiveMatrix);
            shader.setTexture(texture: gameObject.model.texture);
            gameObject.model.render();
        }
    }
}