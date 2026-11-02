# Minimal Modern Lock view with quiet status

Optional view overlay for an existing compatible `daemon0.modern-lock` host. Copy all four implementation files together: `LockView.qml`, `LockTelemetry.qml`, `LockStats.js` and the license. It is not installed automatically. Keep the host service, PAM and fingerprint policy in place.

The existing clock and masked password field stay central. A small date and one quiet CPU/RAM/battery line add glanceable status without charts or controls. Read-only `/proc/stat` deltas and `/proc/meminfo` available memory provide CPU and RAM; UPower supplies battery presence/percentage and external-power state. Missing or warming-up readings show a dash; zero remains valid. There are no shell commands, network requests, privileged probes or new services. Sampling starts only while the view has a visible window, uses a one-second interval, and the optional provider is destroyed when the view closes.

Tests exercise parser boundaries, real read-only measurements, masked input, keyboard focus, busy/error feedback, compact layout and reduced motion. An inert preview does not establish real SessionLock or PAM acceptance. Back up your current view and verify the matching host before installing. User-specific power and authentication service code is excluded from this reference.
