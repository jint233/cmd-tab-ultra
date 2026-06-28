APP      := CmdTabUltra
SWIFT    := swiftc
FLAGS    := -O -framework Cocoa -framework ApplicationServices
SOURCES  := $(wildcard src/*.swift)
DIST     := dist
SIGN_IDENTITY ?= -
INSTALLER_SIGN_IDENTITY ?=
RESET_ACCESSIBILITY ?= 1

.PHONY: all help universal arm64 x86_64 icon clean format lint bundle zip dmg pkg package install uninstall

all: universal

help:
	@echo "Available targets:"
	@echo "  make universal   Build the universal binary"
	@echo "  make bundle      Build the app bundle"
	@echo "  make zip         Build the ZIP archive"
	@echo "  make dmg         Build the DMG image"
	@echo "  make pkg         Build the installer package"
	@echo "  make lint        Check Swift formatting"
	@echo "  make format      Apply Swift formatting"
	@echo "  make install     Install the app locally"
	@echo "  make uninstall   Remove the local install"
	@echo "  make clean       Remove build artifacts"

$(DIST):
	mkdir -p $@

$(DIST)/$(APP)-arm64: $(SOURCES) | $(DIST)
	$(SWIFT) $(FLAGS) -target arm64-apple-macosx11.0 $(SOURCES) -o $@

$(DIST)/$(APP)-x86_64: $(SOURCES) | $(DIST)
	$(SWIFT) $(FLAGS) -target x86_64-apple-macosx11.0 $(SOURCES) -o $@

$(DIST)/$(APP): $(DIST)/$(APP)-arm64 $(DIST)/$(APP)-x86_64
	lipo -create -output $@ $^
	rm $(DIST)/$(APP)-arm64 $(DIST)/$(APP)-x86_64
	@echo "Built universal binary: $@"

arm64:   $(DIST)/$(APP)-arm64
x86_64:  $(DIST)/$(APP)-x86_64
universal: $(DIST)/$(APP)

clean:
	rm -rf $(DIST)

# Packaging and installation variables
PLIST_LABEL   := com.jint233.cmdtabultra
PLIST_SRC     := $(PLIST_LABEL).plist
PLIST_DST     := $(HOME)/Library/LaunchAgents/$(PLIST_SRC)
LAUNCHD_UID   := gui/$$(id -u)
VERSION       := $(shell /usr/libexec/PlistBuddy -c "Print :Version" $(PLIST_SRC))
ICON_SRC      := resources/$(APP).icns
PKG_ID        := com.jint233.cmdtabultra.pkg
PKG_ROOT      := $(DIST)/pkgroot
PKG_SCRIPTS   := $(DIST)/pkg-scripts
PKG_UNSIGNED  := $(DIST)/$(APP)-$(VERSION)-unsigned.pkg
PKG_OUT       := $(DIST)/$(APP)-$(VERSION).pkg
DMG_ROOT      := $(DIST)/dmgroot
DMG_RW        := $(DIST)/$(APP)-$(VERSION)-rw.dmg
DMG_OUT       := $(DIST)/$(APP)-$(VERSION).dmg
DMG_VOLUME    := $(APP)
DMG_MOUNT     := /Volumes/$(DMG_VOLUME)

# Local target directories for bundle build
DIST_APP      := $(DIST)/$(APP).app
DIST_CONTENTS := $(DIST_APP)/Contents
DIST_MACOS    := $(DIST_CONTENTS)/MacOS
DIST_RESOURCES:= $(DIST_CONTENTS)/Resources
DIST_BIN      := $(DIST_MACOS)/$(APP)
DIST_INFO     := $(DIST_CONTENTS)/Info.plist
DIST_ICON     := $(DIST_RESOURCES)/$(APP).icns

# System application path
APP_BUNDLE    := $(HOME)/Applications/$(APP).app
INSTALL_BIN   := $(APP_BUNDLE)/Contents/MacOS/$(APP)

icon:
	swift scripts/make_command_arrow_icon.swift

# Formatting
format:
	@xcrun --find swift-format >/dev/null 2>&1 || (echo "swift-format not found" && exit 1)
	xcrun swift-format format --in-place --recursive src scripts

lint:
	@xcrun --find swift-format >/dev/null 2>&1 || (echo "swift-format not found" && exit 1)
	xcrun swift-format lint --recursive src scripts

# Packaging
bundle: universal icon
	rm -rf "$(DIST_APP)"
	mkdir -p "$(DIST_MACOS)" "$(DIST_RESOURCES)"
	cp "$(DIST)/$(APP)" "$(DIST_BIN)"
	chmod 755 "$(DIST_BIN)"
	cp "$(ICON_SRC)" "$(DIST_ICON)"
	for localization in resources/*.lproj; do \
		if [ -d "$$localization" ]; then \
			cp -R "$$localization" "$(DIST_RESOURCES)/"; \
		fi; \
	done
	rm -f "$(DIST_INFO)"
	plutil -create xml1 "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $(PLIST_LABEL)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleName string $(APP)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $(APP)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $(VERSION)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $(VERSION)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $(APP)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $(APP)" "$(DIST_INFO)"
	/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$(DIST_INFO)"
	xattr -dr com.apple.quarantine "$(DIST_APP)" 2>/dev/null || true
	codesign --force --deep --sign "$(SIGN_IDENTITY)" "$(DIST_APP)" 2>/dev/null || true
	@echo "Packaged app bundle to: $(DIST_APP)"

zip: bundle
	rm -f "$(DIST)/$(APP)-universal.zip"
	cd $(DIST) && zip -q -r "$(APP)-universal.zip" "$(APP).app"
	@echo "Created distributable ZIP: $(DIST)/$(APP)-universal.zip"

dmg: bundle
	-hdiutil detach "$(DMG_MOUNT)" 2>/dev/null || true
	rm -rf "$(DMG_ROOT)" "$(DMG_MOUNT)" "$(DMG_RW)" "$(DMG_OUT)"
	mkdir -p "$(DMG_ROOT)"
	cp -R "$(DIST_APP)" "$(DMG_ROOT)/$(APP).app"
	ln -s /Applications "$(DMG_ROOT)/Applications"
	hdiutil create \
		-volname "$(DMG_VOLUME)" \
		-srcfolder "$(DMG_ROOT)" \
		-ov \
		-fs HFS+ \
		-format UDRW \
		"$(DMG_RW)"
	hdiutil attach "$(DMG_RW)" -readwrite -noverify -noautoopen -mountpoint "$(DMG_MOUNT)"
	osascript \
		-e 'tell application "Finder"' \
		-e 'tell disk "$(DMG_VOLUME)"' \
		-e 'open' \
		-e 'set current view of container window to icon view' \
		-e 'set toolbar visible of container window to false' \
		-e 'set statusbar visible of container window to false' \
		-e 'set pathbar visible of container window to false' \
		-e 'set bounds of container window to {100, 100, 720, 460}' \
		-e 'set viewOptions to icon view options of container window' \
		-e 'set arrangement of viewOptions to not arranged' \
		-e 'set icon size of viewOptions to 96' \
		-e 'set position of item "$(APP).app" to {155, 135}' \
		-e 'set position of item "Applications" to {465, 135}' \
		-e 'close' \
		-e 'end tell' \
		-e 'end tell' || true
	sync
	hdiutil detach "$(DMG_MOUNT)"
	hdiutil convert "$(DMG_RW)" \
		-format UDZO \
		-ov \
		-o \
		"$(DMG_OUT)"
	rm -rf "$(DMG_MOUNT)" "$(DMG_RW)"
	@echo "Created disk image: $(DMG_OUT)"

pkg: bundle
	rm -rf "$(PKG_ROOT)" "$(PKG_SCRIPTS)" "$(PKG_UNSIGNED)" "$(PKG_OUT)"
	mkdir -p "$(PKG_ROOT)/Library/Application Support/$(APP)" "$(PKG_SCRIPTS)"
	cp -R "$(DIST_APP)" "$(PKG_ROOT)/Library/Application Support/$(APP)/$(APP).app"
	cp "packaging/postinstall" "$(PKG_SCRIPTS)/postinstall"
	chmod 755 "$(PKG_SCRIPTS)/postinstall"
	pkgbuild \
		--root "$(PKG_ROOT)" \
		--component-plist "packaging/components.plist" \
		--scripts "$(PKG_SCRIPTS)" \
		--identifier "$(PKG_ID)" \
		--version "$(VERSION)" \
		--install-location "/" \
		"$(PKG_UNSIGNED)"
	if [ -n "$(INSTALLER_SIGN_IDENTITY)" ]; then \
		productsign --sign "$(INSTALLER_SIGN_IDENTITY)" "$(PKG_UNSIGNED)" "$(PKG_OUT)"; \
		rm -f "$(PKG_UNSIGNED)"; \
	else \
		mv "$(PKG_UNSIGNED)" "$(PKG_OUT)"; \
	fi
	@echo "Created installer package: $(PKG_OUT)"

package: zip dmg pkg

# Installation
install: bundle
	@# stop current service
	-launchctl bootout $(LAUNCHD_UID) "$(PLIST_DST)" 2>/dev/null
	if [ "$(RESET_ACCESSIBILITY)" != "0" ]; then \
		tccutil reset Accessibility $(PLIST_LABEL) 2>/dev/null || true; \
	fi
	@# copy app bundle
	mkdir -p "$$(dirname "$(APP_BUNDLE)")"
	rm -rf "$(APP_BUNDLE)"
	cp -R "$(DIST_APP)" "$(APP_BUNDLE)"
	@# install LaunchAgent plist
	mkdir -p "$$(dirname "$(PLIST_DST)")"
	sed "s|__BINARY__|$(INSTALL_BIN)|g" "$(PLIST_SRC)" > "$(PLIST_DST)"
	launchctl enable "$(LAUNCHD_UID)/$(PLIST_LABEL)"
	open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
	open "$(APP_BUNDLE)" 2>/dev/null || true
	@echo "Installed. Please grant Accessibility permission, then start the service from $(APP_BUNDLE)."

uninstall:
	-launchctl bootout $(LAUNCHD_UID) $(PLIST_DST) 2>/dev/null
	-tccutil reset Accessibility $(PLIST_LABEL) 2>/dev/null
	-rm -rf "$(APP_BUNDLE)" "$(PLIST_DST)"
	@echo "Uninstalled."
