# Location-Based Scavenger Hunt Game

## Overview
This project is an interactive scavenger hunt game developed using Swift and SwiftUI. The application uses GPS coordinates to generate randomized location-based challenges for players. Users must physically travel to designated locations, take pictures as proof, and complete the scavenger hunt within a time limit. The game leverages MapKit and CoreLocation to track the user's location in real-time and determine proximity to the game-generated pins.

## Features
- **Dynamic Map Integration**: Displays user’s current location and game-generated pins on an interactive map.
- **Pin Generation**: Players input the number of pins and a search radius; the system randomly places pins within that radius.
- **Real-Time Proximity Detection**: Determines if a user is near a pin and allows photo capture only when they are close.
- **Camera Integration**: Uses device camera to take photos, storing them as verification for completed locations.
- **Countdown Timer**: Players have a limited time to find and capture all locations.
- **Win/Loss Conditions**: The game tracks collected locations and announces victory when all pins are found or loss if the timer runs out.
- **Photo Review**: After the game, players can view all captured photos in a carousel format.

## Technologies Used
- **SwiftUI**: For building the user interface.
- **MapKit**: For handling map display, pin placement, and region monitoring.
- **CoreLocation**: To track and update the user's GPS location.
- **UIKit**: For integrating camera functionality within the SwiftUI application.
- **Timers & Bindings**: Used for real-time countdown and interactive UI updates.

## Core Components & Functionality
### **Map Location Structure**
The `MapLocation` struct stores each pin’s coordinates, name, and image (if a photo is taken). It provides a computed property for easy access to the `CLLocationCoordinate2D` representation.

### **Proximity & Interaction Logic**
- The game determines when the user is near a pin (within 15 meters) and allows them to take a photo.
- The closest pin is dynamically identified to update gameplay interactions.
- Pins change color to indicate completion: **Red (not found), Green (photo taken).**

### **Game Lifecycle**
1. User specifies **number of pins** and **search radius**.
2. Pins are randomly generated around the user's location.
3. Timer starts and user begins searching.
4. When within range, the user takes a photo to mark the pin as found.
5. Game ends when either:
   - All pins are found (**Victory!**)
   - Time runs out (**Loss!**)
6. Players can review their captured photos post-game.

## User Interface
- **Navigation View**: Organizes UI components.
- **Dynamic Map View**: Displays user and pin locations.
- **Status Bar**: Shows remaining pins and countdown timer.
- **Interactive Buttons**: Include "Zoom to Location," "Restart Game," and "Take Photo."
- **Popups & Alerts**: Indicate game status (win/loss) and enable photo review.

## Key Classes & Structs
- `MapLocation`: Stores data for each game pin.
- `ContentView`: Main UI view handling game interactions.
- `LocationViewModel`: Manages location permissions and updates user location.
- `MapView`: Handles the rendering and updating of map elements.
- `ImagePicker`: Implements camera functionality.
- `CarouselView`: Displays collected photos after the game.

## Skills Demonstrated
1. **SwiftUI Development**: Implemented UI components with state management.
2. **Location Services**: Utilized CoreLocation to track real-time movement.
3. **MapKit Integration**: Added interactive map with dynamic pin updates.
4. **Camera & Image Processing**: Captured and displayed photos within the app.
5. **Timer & State Handling**: Managed game logic with countdown and bindings.
6. **User Experience Design**: Created an engaging scavenger hunt experience.

## Future Enhancements
- **Multiplayer Mode**: Allow multiple users to compete in real-time.
- **Persistent Storage**: Save previous game sessions and leaderboards.
- **Augmented Reality Features**: Use AR to enhance pin discovery experience.
- **Dynamic Difficulty Scaling**: Adjust radius and pin count based on skill level.

## Conclusion
This project showcases how real-world geolocation and interactive UI elements can create a fun and immersive scavenger hunt experience. By combining **SwiftUI, MapKit, CoreLocation, and camera functionalities**, this game delivers an engaging challenge where users must physically explore their environment to succeed.
