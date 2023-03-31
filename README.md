# Automatically Install Element Nightly on Arch Linux

[get-upgrade-element-nightly.sh](get-upgrade-element-nightly.sh) download and verifies the official Element Nightly .deb package, converts it to Arch and installs it.

## Usage
1. Import the [element.io archive keyring](https://packages.element.io/debian/element-io-archive-keyring.gpg) via `gpg --import ...`
2. Run the script. The installation step uses `makepkg -i` so it will ask you to elevate your privileges
