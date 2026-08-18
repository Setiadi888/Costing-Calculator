# Costing Calculator

An iPhone app for costing a product up from its parts: injection mouldings,
imported items, finishing and labour. Each item is worked out from its own
inputs, the items add up to a grand total, and finished costings are kept so
they can be compared or added together.

## Requirements

- Xcode 16 or newer, on a Mac
- An iPhone running iOS 17 or newer (or the iPhone simulator)

## Running it

**In the simulator** — open `Costing Calculator.xcodeproj`, pick any iPhone
simulator from the scheme menu, and press ⌘R.

**On your own iPhone:**

1. Plug the iPhone into the Mac and trust the computer when asked.
2. In Xcode, select the **Costing Calculator** target → **Signing &
   Capabilities**.
3. Set **Team** to your Apple ID. Add one under Xcode → Settings → Accounts if
   there isn't one there yet; a free Apple ID is enough.
4. The bundle identifier ships as a placeholder,
   `www.abcabc.com.Costing-Calculator`. Change it to something of your own —
   `com.yourname.costingcalculator` — if Xcode says it is unavailable.
5. Choose the iPhone from the scheme menu and press ⌘R.
6. The first launch is blocked by iOS. On the phone, go to **Settings →
   General → VPN & Device Management**, tap your Apple ID, and trust it. Then
   open the app again.

An app signed with a free Apple ID stops working after seven days. Plugging
the phone in and pressing ⌘R again renews it. A paid Apple Developer account
raises that to a year.

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
