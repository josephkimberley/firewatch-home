# Public installer and recovery requirements

This is a release design, not executable recovery instructions. The development TV's exact recovery records remain in its private change register and backups. Do not use this document to reconstruct those device-specific transactions.

Before any public root integration, the installer must positively identify supported firmware and stock file hashes, record existing settings and mounts, create verified backups outside the app package, and refuse unknown or already-modified state. A model name alone is insufficient compatibility evidence.

The transaction receipt must record installer version, changed paths, original and installed hashes, settings before/after, permissions, boot hooks and ordering dependencies. Never overwrite a modified file during rollback without resolving the mismatch. Retain backups across app upgrades and uninstall until rollback has been verified.

Keep a stock LG Home route and an independent disable/recovery path. Disable integration before removing its app. Restore dependent overlays in reverse order and verify stock input, Settings, power-off, wake and HDMI/CEC behavior. Do not ship an installer that requires unexplained manual restarts of core LG services.

App uninstall, disabling custom Home integration, removing root and restoring firmware are different operations. This project cannot promise recovery from every hardware or boot failure, and a settings backup is not a firmware image. Picture settings and account sessions also have different backup limits; no public installer should promise to preserve them without evidence.

Do not blanket-block security updates as a hidden install side effect. Document the supported firmware, update policy and how to disable/uninstall integration before an update. New firmware must fail closed until compatibility is reviewed. Keep auto-update decisions explicit to the owner.

This folder includes no SSH keys, pairing records, TV network address, account data, proprietary firmware copies or private backup receipts. Logs submitted publicly should remove device IDs, addresses, tokens and account details.
