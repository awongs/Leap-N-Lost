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
    
    // Array of all point lights in the scene
    var pointLights : [PointLight];
    
    // Array of all spot lights in the scene
    var spotLights : [SpotLight];

    // List of all game objects in the scene
    var gameObjects : [GameObject];
    
    // List of all tiles in the scene
    var tiles : [Tile];
    
    // Reference to the player object.
    var player : PlayerGameObject;
    
    // Dictionary containing references of objects.
    var collisionDictionary : [Int: [GameObject]];
    
    // Camera properties
    private(set) var mainCamera : CameraFollowTarget;
    
    // The level
    private(set) var level : Level;
    
    // Reference to the game view.
    private var view : GLKView;
    
    // Current area
    var currArea: Int;
    
    // Current level
    var currLevel: Int;
    
    // The current score
    var score : Int = 0;
    
    // Total time of this run
    var totalTime : Float = 0.0;
    
    var pause: Bool = false;
    
    
    /**
     * Constructor, initializes the scene.
     * view - reference to the game view
     */
    init(view: GLKView) {
        // Initialize variables
        self.view = view;
        self.level = Level();
        self.gameObjects = [GameObject]();
        self.tiles = [Tile]();
        self.collisionDictionary = [Int:[GameObject]]();
        self.currArea = -1;
        self.currLevel = -1;
        self.pointLights = [PointLight]();
        self.spotLights = [SpotLight]();
        
        let animal : Animal = PlayerProfile.loadFromFile()!.animalList.getCurrentAnimal();
        
        let frogModel : Model = ModelCacheManager.loadModel(withMeshName: animal.modelFileName, withTextureName: animal.textureFileName)!;
        
        player = PlayerGameObject.init(withModel: frogModel);
        player.type = "Player";
        gameObjects.append(player);
        
        directionalLight = DirectionalLight(color: Vector3(1, 1, 0.8), ambientIntensity: 0.5, diffuseIntensity: 1, specularIntensity: 1, direction: Vector3(0, -2, -5));
        
        // Setup the camera
        let camOffset : Vector3 = Vector3(0, -14, -8.5);
        mainCamera = CameraFollowTarget(cameraOffset: camOffset, trackTarget: player);
        
        // For testing purposes ***
        mainCamera.rotate(xRotation: Float.pi / 4, yRotation: 0, zRotation: 0);
        
        // Have to set current scene here because of swift
        player.currentScene = self;
    }
    
    /**
     * Gets a tile from the given row and column
     */
    func getTile(row: Int, column: Int) -> Tile? {
        // Check if row and column are valid
        if (row >= 0 && row < level.rows.count && column >= 0 && column < Level.tilesPerRow) {
            return tiles[Level.tilesPerRow * row + column];
        }
        
        return nil;
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
        var theme : Theme? = nil;
        
        switch (self.level.info.theme) {
        case "City":
            theme = City();
        case "Jungle":
            theme = Jungle();
        case "Lab":
            theme = Lab();
        default:
            print("ERROR: Invalid level theme");
        }
      
        self.currLevel = self.level.info.level;
        self.currArea = self.level.info.area;
      
        // Generate tiles for each row
        for rowIndex in 0..<self.level.rows.count {
            let row = self.level.rows[rowIndex];
            
            // Parse row and tile objects based on the level's theme
            let rowObjects : [GameObject] = theme!.parseRowObjects(row: row, rowIndex: rowIndex);
            let rowTiles : [Tile] = theme!.parseRowTiles(row: row, rowIndex: rowIndex);
            
            // Save to collision dictionary
            collisionDictionary[rowIndex] = rowObjects;
            
            // Append objects and tiles to the level
            self.gameObjects.append(contentsOf: rowObjects);
            self.tiles.append(contentsOf: rowTiles);
        }
        
        // Spawn coins
        spawnCoins();
        
        // Creating a MemoryFragment and appending to gameobjects.
        let memoryFragment = MemoryFragment(position: getTile(row: self.level.rows.count - 1, column: Level.tilesPerRow / 2)!.position + Vector3(0, 2, 0), row: self.level.rows.count - 1);
        
        // Change fragment model to ship on level 3-5
        if (theme is Lab && self.level.info.level == 5) {
            memoryFragment.model = ModelCacheManager.loadModel(withMeshName: "ship", withTextureName: "ship.png", saveToCache: true)!;
            memoryFragment.scale = Vector3(0.04, 0.04, 0.04);
            memoryFragment.rotation = Vector3(0, 0, 0);
        }

        gameObjects.append(memoryFragment);
        collisionDictionary[self.level.rows.count - 1]!.append(memoryFragment);

        // Apply night settings if it's a night level
        if (self.level.info.night == true) {
            // Dim the directional light
            directionalLight = DirectionalLight(color: Vector3(0.8, 1, 0.8), ambientIntensity: 0.02, diffuseIntensity: 0.04, specularIntensity: 0.02, direction: Vector3(0, -2, -5));
            
            // Add the theme's night lights.
            pointLights.append(contentsOf: theme!.setupPointLights(gameObjects: gameObjects));
            spotLights.append(contentsOf: theme!.setupSpotLights(gameObjects: gameObjects));
            
            // Add the player's light
            pointLights.append(player.nightLight);
        }
        
        // Set player position
        player.teleportToTarget(target: getTile(row: 0, column: Level.tilesPerRow / 2)!);
    }
    
    /**
     * Restarts the level by putting the player back at the starting tile.
     * Also respawns coins, but does not reset position of any other game objects.
     */
    func restartLevel() {
        score = 0; // Reset the score
        totalTime = 0.0;
        player.reset();
        spawnCoins();
    }
    
    /**
     * Generates coins for every third row.
     * If there are any existing coins, they will be removed first.
     */
    func spawnCoins() {
        // Remove all existing coins
        gameObjects.removeAll(where: {$0 is Coin});
        for i in 0..<collisionDictionary.count {
            collisionDictionary[i]!.removeAll(where: {$0 is Coin});
        }
        
        // Spawn a coin every third row
        for rowIndex in 0..<self.level.rows.count {
            if(rowIndex % 3 == 0) {
                // Cap column between 2 and 12
                let randomNumber : Int = Int.random(in: 2..<Level.tilesPerRow - 2);
                let coin = Coin(position: getTile(row: rowIndex, column: Level.tilesPerRow - randomNumber)!.position + Vector3(0,2,0), row: rowIndex);
                gameObjects.append(coin);
                collisionDictionary[rowIndex]!.append(coin);
            }
        }
    }
    
    /**
     * Update loop.
     * delta - the time since last frame
     */
    func update(delta: Float) {
        // Create a projection matrix
        //mainCamera.calculatePerspectiveMatrix(viewWidth: view.drawableWidth, viewHeight: view.drawableHeight, fieldOfView: 60, nearClipZ: 1, farClipZ: 40);
        //mainCamera.calculateOrthographicMatrix(viewWidth: Int(view.window!.frame.width), viewHeight: Int(view.window!.frame.height), nearClipZ: 0.1, farClipz: 50);
        mainCamera.calculateOrthographicMatrix(viewWidth: view.drawableWidth, viewHeight: view.drawableHeight, orthoWidth: 10, orthoHeight: 10, nearClipZ: 0.1, farClipz: 50);
        
        // Loop through every object in scene and call update
        for gameObject in gameObjects {
            // Check if gameObject is out of view
            if(gameObject.position.z > player.position.z + 50 ||
                gameObject.position.z < player.position.z - 50)
            {
                gameObject.model.inView = false;
            } else {
                gameObject.model.inView = true;
            }
            
            if(!pause){
                gameObject.update(delta: delta);
            }
        }
        
        mainCamera.updatePosition();
        
        if (player.tileRow >= 30) {
            player.isGameOver = true;
        }
        
        if (!player.isDead && !player.isGameOver) {
            totalTime = totalTime + delta;
        }
        
    }
    
    func saveScoreToScoreboard() {
        let pp : PlayerProfile = PlayerProfile.loadFromFile()!;
        
        pp.scoreboard.getLevelScoreboard(forWorld: currArea - 1, forLevel: currLevel - 1).tryInsertScore(withScore: score);
        
        pp.saveToFile();
        
        print("End of level, saving to scoreboard if possible \(score) for \(currArea)-\(currLevel)");
    }
}
