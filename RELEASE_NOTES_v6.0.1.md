# Strawberry Jam v6.0.1

Fixes for buddy cards and the marketplace, room joins that keep trying when a room is full, and a cleaner Network log.

Download: `strawberry-jam-Setup-6.0.1.exe` from the Releases page, or let the app update itself.

## New

- **Retry Follow Buddy (Room Full).** New toggle in the Mod Menu's Enhancements tab. When a buddy is in a full room, the buddy card's **Go to room** keeps retrying every 2 seconds until you get in. A small banner shows while it tries, with a **Stop** button to cancel.

## Improvements

- **Network log redesign.** Each packet is now one compact row with a timestamp, a direction arrow, a command badge, and dimmed `%` separators. About twice as many packets fit on screen.
- **Teleport retries.** Teleporting to another room now keeps retrying until you arrive, instead of sending one request and closing the popup.
- **Mod Menu cleanup.** The Mod Menu now releases its event listeners and resources properly when it closes.

## Fixes

- **Nametag buddy cards.** Clicking another player's nametag in a room now opens their buddy card, so you can get to their trade list from there.
- **Marketplace.** The **Trade For** and **View User** buttons no longer throw an error, so marketplace listings show up again.
- **Network log auto-scroll.** The log follows new packets again while you're at the bottom. Scroll up to pause it, then click **Jump to latest** to resume.
- **Outgoing counter.** The "out" count now goes down correctly when old packets are trimmed at the log limit.
