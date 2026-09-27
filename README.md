# babybug

A cosy virtual pet game for young kids on iPhone and iPad. A little princess or prince looks after a mini rabbit in a magical watercolour garden.

## Open and run

1. Open `babybug.xcodeproj` in Xcode 16 or newer.
2. Pick an iPhone simulator at the top of the window and press Run (⌘R).
3. To run on your own iPhone, select the **babybug** target, open **Signing & Capabilities**, and choose your Apple ID under **Team**.

## What's here so far

- On first launch, pick the princess or the prince on a Y2K-style sticker page (the crown button switches later).

Painted art made with Gemini from the project prompts: the garden background and the bunny. The princess and prince are from Gemini too; only the carrot is still a placeholder.

- Tap the bunny to tickle it (happiness goes up).
- Drag the carrot onto the bunny to feed it (hunger goes up).
- Rub the bunny back and forth for a bubble bath (clean bar goes up).
- Tap the bellflower cottage to put the bunny to bed: the garden turns to a starry night and the energy bar fills. Tap anywhere to wake it.
- The bars slowly go down over real time and are saved between launches.
- The bunny has moods: hungry (carrot bubble), lonely (heart bubble), dirty (bubbles), sleepy when tired, sleepy at bedtime (8pm to 7am, zzz bubble), happy when well cared for. Each mood uses its own picture (`BunnyHappy`, `BunnyHungry`, `BunnyLonely`, `BunnySleepy` in the asset catalog) and falls back to the default bunny until that picture is added.

- The bunny grows up: baby, then young after 3 days of care, then grown after 7 (a day counts once the child feeds, tickles or bathes it). Growing up plays a sparkle shower and "Your bunny grew!". For testing, press and hold the bars at the top for 2 seconds to grow it straight away. Pictures are `BunnyYoung…` and `BunnyGrown…` (for example `BunnyYoungHappy`); until they're added, the baby's pictures are shown bigger.

## Code map

- `babybug/BabybugApp.swift`: app entry point
- `babybug/ContentView.swift`: SwiftUI screen holding the garden and the stat bars
- `babybug/GardenScene.swift`: SpriteKit garden, bunny, and touch handling
- `babybug/PetStats.swift`: the bunny's needs, real-time decay and saving
- `babybug/Mood.swift`: which mood the bunny is in
- `babybug/Stage.swift`: baby, young and grown, and when each one starts
- `babybug/Hero.swift`, `babybug/HeroPicker.swift`: choosing the princess or prince
- `babybug/AppFont.swift`, `babybug/Fonts/`: the Yuji Mai font (by Kinuta Font Factory, free under the SIL Open Font License 1.1, from Google Fonts)
