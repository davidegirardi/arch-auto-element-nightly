set -o errexit

RELEASE="https://packages.element.io/debian/dists/bullseye/Release"
RELEASE_GPG="https://packages.element.io/debian/dists/bullseye/Release.gpg"
PACKAGES="https://packages.element.io/debian/dists/bullseye/main/binary-amd64/Packages"
PACKAGE_NAME="element-desktop-nightly-bin"

function renderPKGBUILD() {
    DEB_PATH="$1"
    VERSION="$2"
    cat << SHEOF > element-desktop-nightly.sh
#!/bin/sh
LD_PRELOAD=/usr/lib/libsqlcipher.so exec "/opt/Element-Nightly/element-desktop-nightly" "$@"
SHEOF

cat << EOF > PKGBUILD
pkgname=$PACKAGE_NAME
pkgver=$VERSION
pkgrel=1
pkgdesc="All-in-one secure chat app for teams, friends and organisations (nightly .deb build)."
arch=('x86_64')
url="https://element.io"
license=('Apache')
depends=('sqlcipher')
source=("https://packages.element.io/debian/$DEB_PATH"
        "element-desktop-nightly.sh")
replaces=('riot-desktop-nightly-bin')
package() {
  msg2 "Extracting the data.tar.xz..."
  bsdtar -xf data.tar.xz -C "\$pkgdir/"
  install -Dm755 "\${srcdir}"/element-desktop-nightly.sh "\${pkgdir}"/usr/bin/element-desktop-nightly
  sed -i 's|^Exec=.*|Exec=/usr/bin/element-desktop-nightly %U|' "\${pkgdir}"/usr/share/applications/element-desktop-nightly.desktop
}
EOF

    # Generate the final PKGBUILD
    makepkg --geninteg >> PKGBUILD
}


function main() {
    WD=$(mktemp -d)
    cd "$WD"
    # Get the repository files
    curl "$RELEASE" -so Release
    curl "$RELEASE_GPG" -so Release.gpg
    curl "$PACKAGES" -so Packages
    # Verify the signature
    if gpg --verify Release.gpg  Release &> /dev/null
    then
        PACKAGES_HASH=$(sha256sum Packages | awk '{print $1}')
        if grep "$PACKAGES_HASH" Release > /dev/null
        then
            DEB_PATH=$(awk '/^Filename:\s.*element-nightly_[0-9]+_amd64.deb/{print $2}' Packages)
            VERSION=$(echo "$DEB_PATH" | awk -F _ '{print $2}')
            if pacman -Qi $PACKAGE_NAME | grep "$VERSION" > /dev/null
            then
                echo "Package $PACKAGE_NAME version $VERSION already up to date, exiting"
                rm -r "$WD"
                return 0
            fi
            renderPKGBUILD "$DEB_PATH" "$VERSION"
            # Download the .deb file
            makepkg --nobuild
            DEB_FILENAME=$(basename $DEB_PATH)
            DEB_HASH=$(sha256sum "$DEB_FILENAME" | awk '{print $1}')
            if grep "$DEB_HASH" Packages
            then
                makepkg -i
                rm -r "$WD"
            else
                echo "Invalid deb file hash ($DEB_HASH)"
                echo Check $WD
            fi
        else
            echo "Invalid Package hash ($PACKAGES_HASH)"
            echo Check $WD
        fi
    else
        echo Invalid Release signature
            echo Check $WD
    fi
}

main
