# babybug

A cosy virtual pet game for young kids on iPhone and iPad. A little princess or prince looks after a mini rabbit in a magical watercolour garden.

## Open and run

1. Open `babybug.xcodeproj` in Xcode 16 or newer.
2. Pick an iPhone simulator at the top of the window and press Run (⌘R).
3. To run on your own iPhone, select the **babybug** target, open **Signing & Capabilities**, and choose your Apple ID under **Team**.

## What's here so far

A painted garden with the bunny (made with Gemini from the project prompts). The garden and carrot are placeholders until their AI versions arrive.

- Tap the bunny to tickle it (happiness goes up).
- Drag the carrot onto the bunny to feed it (hunger goes up).
- Both bars slowly go down over real time and are saved between launches.

## Code map

- `babybug/BabybugApp.swift`: app entry point
- `babybug/ContentView.swift`: SwiftUI screen holding the garden and the stat bars
- `babybug/GardenScene.swift`: SpriteKit garden, bunny, and touch handling
- `babybug/PetStats.swift`: the bunny's needs, real-time decay and saving
