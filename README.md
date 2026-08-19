# Costing Calculator

An iPhone app for costing a product up from its parts: injection mouldings,
imported items, finishing and labour. Each item is worked out from its own
inputs, the items add up to a grand total, and finished costings are kept so
they can be compared or added together.

## Requirements

- Xcode 16 or newer, on a Mac
- An iPhone running iOS 17 or newer (or the iPhone simulator)

## Putting it on your iPhone

The work lives on the `claude/ios-app-iphone-tvt10p` branch, not `main`, so
step 1 is not optional — skip it and Xcode opens the old version.

**1. Get the current code.** In Terminal, from the project folder:

```
git fetch origin
git checkout claude/ios-app-iphone-tvt10p
git pull origin claude/ios-app-iphone-tvt10p
git log --oneline -1
```

That last line should print `Price injection material in Rupiah only`. If it
prints something else, the pull did not take.

**2. Open the project.**

```
open "Costing Calculator.xcodeproj"
```

**3. Sign it.** Click **Costing Calculator** at the top of the left sidebar,
then the **Costing Calculator** target, then the **Signing & Capabilities**
tab. Tick **Automatically manage signing** and set **Team** to your Apple ID.
No Apple ID listed? Xcode → Settings → Accounts → **+** → Apple ID. A free
one is enough.

**4. Give it a bundle identifier of your own, if asked.** It ships as
`www.abcabc.com.Costing-Calculator`, a placeholder. If Xcode says the
identifier is unavailable, change it to something nobody else will have:
`com.yourname.costingcalculator`.

**5. Unlock the phone.** It must be unlocked, and you must have tapped
**Trust** on the "Trust This Computer?" prompt. Until then Xcode will not
list it.

**6. Turn on Developer Mode.** On the phone: **Settings → Privacy & Security
→ Developer Mode → on**, then restart the phone when it asks. iOS will not
run a self-signed app without it. The option only appears once Xcode has
tried to use the device, so if you cannot find it, do step 7 first and come
back.

**7. Pick the phone and run.** Choose it from the device menu at the top of
the Xcode window — by name, not a simulator — and press **⌘R**.

**8. Trust the developer.** The first launch is refused with "Untrusted
Developer". On the phone: **Settings → General → VPN & Device Management** →
tap your Apple ID → **Trust**. Open the app again and it starts.

### When something goes wrong

| Xcode says | Do this |
| --- | --- |
| Signing for "Costing Calculator" requires a development team | Step 3 |
| Failed to register bundle identifier | Step 4 |
| The run destination is not valid / phone missing from the menu | Steps 5 and 6 |
| Untrusted Developer, on the phone | Step 8 |
| Anything red in the editor before it builds | A compile error — send it over |

### Two things to know

An app signed with a free Apple ID stops working after **seven days**. Plug
the phone in and press ⌘R again to renew it. A paid Apple Developer account
raises that to a year.

To run it without a phone at all, pick any iPhone simulator from the same
device menu and press ⌘R. Signing is not needed for the simulator.

## How a costing is built

Each category is costed its own way:

| Category | Worked out from |
| --- | --- |
| Injection part | Material cost per kilo, plus the machine's daily cost split over a day's output |
| Import (sparepart, packaging, product) | Unit price, plus the piece's share of the carton's freight |
| UV | Cost per table, split over the pieces on it |
| Spray, pad print, packaging and assembly labour | A figure entered directly |

Prices can be given in Rupiah, or in RMB with an exchange rate to convert
them — a converted price takes over once both halves are filled in.

Items total to a **Sub Total**. **Lain-lain** adds 7.5% on top and can be
switched off. That gives the **Grand Total**, which is saved as a product.
Saved products stay editable, and the **Final Total** page adds them together.

## Where the data goes

Costings are written to `CostingState.json` in the app's Application Support
directory, so nothing is lost when iOS closes the app in the background.
Deleting the app deletes them with it.
