---
name: no-desktop-automation
description: "Never drive rhY's desktop with xdotool/scrot automation — but the headless macOS VM is explicitly fair game to automate."
metadata: 
  node_type: memory
  pinned: true
  originSessionId: 935c7fb4-c17a-4808-bcea-a8b9e5a58827
  modified: 2026-09-06T20:53:55.097Z
---

# Don't automate rhY's desktop, but do automate the macOS VM

rhY works at this machine while sessions are running. Do not script the host
GUI with `xdotool`, `wmctrl`, `scrot` loops, or any similar input automation.

The failure mode is concrete: while driving a Flutter app to take screenshots,
the game window lost focus and a loop of synthetic clicks landed in rhY's
browser, on a live Cloudflare dashboard page. rhY's response was "Let's not do
anymore automation. I'm using this machine."

Launching an app and taking a single screenshot to check a change is
reasonable; a loop that repeatedly moves the pointer and clicks is not, because
the pointer is shared with a person who is using it. When visual confirmation
of a UI change is needed, prefer approaches that don't seize input: widget or
golden tests, rendering to a file, reasoning from the layout code, or simply
asking rhY to look and report back.

## The exception: the macOS VM

rhY has an OSX-KVM setup at `~/macos-vm` (launched by `run-vm.sh`) and has said
of it: "You can run that and automate that as much as you'd like." It runs
QEMU with `-display none`, a VNC server on `127.0.0.1:5900`, and an SSH
port-forward from host port 2222 to the guest's port 22, so it can be driven
entirely without opening a window on rhY's desktop. Automating inside that VM
— over SSH by preference, or through its own VNC session — does not conflict
with the rule above, because rhY is not using that display.
