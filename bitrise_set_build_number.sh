# Exits if project file does not exists
PBXPROJ_FILE="${BITRISE_PROJECT_PATH}/project.pbxproj"
if [ ! -f $PBXPROJ_FILE ]; then
    echo "[ERROR] Project file not found: ${BITRISE_PROJECT_PATH}"
    exit 1
fi

# Info statements
echo "[INFO] Path of .xcodeproj file:		${BITRISE_PROJECT_PATH}"
echo "[INFO] New Build number:	 		${BITRISE_BUILD_NUMBER}"

# Sets the build number in the .pbxproj file.
echo ""
echo "Replacing..."
sed -i "" "s/\(CURRENT_PROJECT_VERSION = \).*\(;\)/\1${BITRISE_BUILD_NUMBER}\2/" "$PBXPROJ_FILE"
echo ""
echo "[SUCCESS] Replace done!"
