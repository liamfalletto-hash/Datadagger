# Spore Garden: idle game template for iPhone

A small, complete idle/clicker game in SwiftUI, set up so you can change it and play right away.

It includes:

- A tap button with haptics and floating "+N" numbers
- 7 generators with rising costs, plus Buy ×1 / ×10 / ×100 / Max
- Milestones: owning 25, 50, 100… of a generator doubles its output
- One-time upgrades that unlock as you progress
- Prestige: reset your run to earn permanent bonus points
- Offline earnings, with a "Welcome back" popup
- Autosave every 5 seconds and whenever the app goes to the background
- A **Dev** tab with time skips, free currency, 10×/100× speed and a save reset

## Run it on your Mac

1. Install **Xcode** from the Mac App Store (free). Open it once so it can install its components, including the iOS Simulator.
2. Get this repository onto your Mac (GitHub Desktop, or `git clone` in Terminal).
3. Double-click the **`SporeGarden.swiftpm`** folder. It opens in Xcode as an app project. (Or use File → Open in Xcode and pick that folder.)
4. At the top of the Xcode window, choose a simulator such as **iPhone 16**.
5. Press **⌘R** (or click ▶). The iPhone Simulator opens and the game starts.

You click with the mouse to tap. Use ⌘← and ⌘→ to rotate, and ⇧⌘H to go to the home screen. That last one is a quick way to test offline earnings: leave the app for 30 seconds or more, then come back.

### On your real iPhone (optional)

Plug your iPhone in. In Xcode, select it instead of a simulator. You may need to sign in with your Apple ID under Xcode → Settings → Accounts and pick your team under the app's Signing settings. A free Apple ID works for testing on your own phone. The app expires after 7 days and you re-run it from Xcode.

You can also open `SporeGarden.swiftpm` in the **Swift Playgrounds** app on a Mac or iPad.

## Where to play around

| You want to… | Edit |
|---|---|
| Rename the game, currency or emoji | `GameConfig.swift`, at the top |
| Make things cheaper, pricier or faster | `GameConfig.swift`: `baseCost`, `costGrowth`, `baseRate` |
| Add a generator | `GameConfig.swift`: add a `GeneratorDef(...)` line to `generators` |
| Add an upgrade | `GameConfig.swift`: add an `UpgradeDef(...)` to `upgrades` |
| Change prestige | `GameConfig.swift`: `prestige` |
| Change the rules (how multipliers stack, offline pay) | `GameModel.swift` |
| Change colors and layout | `ContentView.swift` (colors are in `Theme` at the top) |

After each change press **⌘R** again.

**Live preview:** in `ContentView.swift`, open the canvas with ⌥⌘↩ to see your view update as you type. To get a preview, add this at the bottom of the file:

```swift
#Preview {
    ContentView().environmentObject(GameModel())
}
```

**Start a fresh save:** use Dev → Reset save, or change `saveKey` in `GameConfig.swift`.

### Ideas to try next

- Balance: change `costGrowth` from `1.15` to `1.07` and see how fast the game snowballs.
- Add achievements to `GameModel`, such as "own 10 of every generator".
- Add a random golden mushroom that appears on screen for a few seconds and gives 60 seconds of income when tapped.
- Add sound with `AVAudioPlayer`.
- Before releasing: set `debug = false`, change `bundleIdentifier` in `Package.swift`, and add a real app icon.

## Files

```
SporeGarden.swiftpm/
├── Package.swift        App settings: name, bundle ID, icon, iOS version
├── GameConfig.swift     All the tunable numbers and content
├── GameModel.swift      Game rules, game loop, saving, offline earnings
├── ContentView.swift    All the screens
└── SporeGardenApp.swift App entry point
```
