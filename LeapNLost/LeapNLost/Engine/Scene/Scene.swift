//
//  Scene.swift
//  LeapNLost
//
//  Created by Anthony Wong on 2019-02-13.
//  Copyright © 2019 bcit. All rights reserved.
//

import Foundation
import GLKit

/**
 * Class that holds information about scenes in the game.
 */
class Scene {
    
    // The directional light in the scene, i.e. the sun
    var directionalLight : DirectionalLight;
    
    // Arrays of all lights in the scene.
    var pointLights : [PointLight];

    // List of all game objects in the scene
    var gameObjects : [GameObject];
    
    // List of all tiles in the scene
    var tiles : [GameObject]
    
    // Camera properties
    private(set) var mainCamera : CameraFollowTarget;
    
    // The level
    private(set) var level : Level;
    
    // Reference to the game view.
    private var view : GLKView;
    
    /**
     * Constructor, initializes the scene.
     * view - reference to the game view
     */
    init(view: GLKView) {
        // Initialize variables
        self.view = view;
        self.level = Level();
        self.gameObjects = [GameObject]();
        self.tiles = [GameObject]();
        
        let frogModel : Model = ModelCacheManager.loadModel(withMeshName: "frog", withTextureName: "frogtex.png")!;
        
        let playerGO : PlayerGameObject = PlayerGameObject.init(withModel: frogModel);
        playerGO.type = "Player";
        gameObjects.append(playerGO);
        playerGO.position = Vector3(0, -3, 0);
        
        // Initialize some test lighting ***
        pointLights = [PointLight]();
        pointLights.append(PointLight(color: Vector3(1, 0, 1), ambientIntensity: 0.2, diffuseIntensity: 1, specularIntensity: 1, position: Vector3(0, 0, -10), constant: 1.0, linear: 0.2, quadratic: 0.1));
        
        directionalLight = DirectionalLight(color: Vector3(1, 1, 0.8), ambientIntensity: 0.2, diffuseIntensity: 1, specularIntensity: 1, direction: Vector3(0, -2, -5));
        
        // Setup the camera
        let camOffset : Vector3 = Vector3(0, -10, -8.5);
        mainCamera = CameraFollowTarget(cameraOffset: camOffset, trackTarget: playerGO);
        
        // For testing purposes ***
        mainCamera.rotate(xRotation: Float.pi / 4, yRotation: 0, zRotation: 0)
    }
    
    /**
     * Loads a level.
     * area - the level area
     * level - the level number
     */
    func loadLevel(area: Int, level: Int) {
        // Parse the level
        let data = self.level.readLevel(withArea: area, withLevel: level);
        self.level = self.level.parseJSON(data: data);
        
        // Generate tiles for each row
        for rowIndex in 0..<self.level.rows.count {
            let row = self.level.rows[rowIndex];
            var texture : String;
            var depth : Float;
            
            // Spawn things
            switch(row.type){
            case "road":
                depth = -5;
                texture = "road.jpg";
                
                // Create car object
                let car = Car.init(pos: Vector3(Float(-Level.tilesPerRow), depth + 2, -Float(rowIndex) * 2), speed: row.speed);
                gameObjects.append(car);
            case "water":
                depth = -5.5;
                
                // Create lilypad object
                let lilypad = Lilypad.init(pos: Vector3(Float(-Level.tilesPerRow), depth + 2, -Float(rowIndex) * 2), speed: row.speed);
                texture = "water.jpg";
                gameObjects.append(lilypad);
            default:
                depth = -5;
                texture = "grass.jpg";
            }
            
            // Generate the row's tiles
            for tileIndex in 0..<Level.tilesPerRow {
                let tile = GameObject.init(Model.CreatePrimitive(primitiveType: Model.Primitive.Cube));
                tile.model.loadTexture(fileName: texture);
                tile.position = Vector3(Float(tileIndex - Level.tilesPerRow / 2) * 2, depth, -Float(rowIndex) * 2);
                tiles.append(tile);
            }
        }
    }
    
    /**
     * Update loop.
     * delta - the time since last frame
     */
    func update(delta: Float) {
        // Create a projection matrix
        mainCamera.calculatePerspectiveMatrix(viewWidth: view.drawableWidth, viewHeight: view.drawableHeight, fieldOfView: 60, nearClipZ: 1, farClipZ: 40);
        
        // Loop through every object in scene and call update
        for gameObject in gameObjects {
            gameObject.update(delta: delta);
        }
        
        mainCamera.updatePosition();
    }
}