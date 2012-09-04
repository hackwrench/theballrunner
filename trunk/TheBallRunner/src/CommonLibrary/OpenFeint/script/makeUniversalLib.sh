#!/bin/bash 

set -o errexit
set -o nounset

UNIVERSAL_DIR="${PROJECT_DIR}/../release/"

mkdir -p "${UNIVERSAL_DIR}"

cp -r "${TARGET_BUILD_DIR}/include" "${UNIVERSAL_DIR}/."

IPHONEOS_INPUT=""
IPHONESIMULATOR_INPUT=""

if [ -f "${SYMROOT}/${CONFIGURATION}-iphoneos/lib${PRODUCT_NAME}.a" ] ; then
	IPHONEOS_INPUT="${SYMROOT}/${CONFIGURATION}-iphoneos/lib${PRODUCT_NAME}.a"
fi

if [ -f "${SYMROOT}/${CONFIGURATION}-iphonesimulator/lib${PRODUCT_NAME}.a" ] ; then
	IPHONESIMULATOR_INPUT="${SYMROOT}/${CONFIGURATION}-iphonesimulator/lib${PRODUCT_NAME}.a"
fi

if [ "${IPHONEOS_INPUT}" ] && [ "${IPHONESIMULATOR_INPUT}" ] ; then
	lipo -create "${IPHONEOS_INPUT}" "${IPHONESIMULATOR_INPUT}" -output "${UNIVERSAL_DIR}/lib${PRODUCT_NAME}.a"
elif [ "${IPHONEOS_INPUT}" ] ; then
	lipo -create "${IPHONEOS_INPUT}" -output "${UNIVERSAL_DIR}/lib${PRODUCT_NAME}.a"
elif [ "${IPHONESIMULATOR_INPUT}" ] ; then
	lipo -create "${IPHONESIMULATOR_INPUT}" -output "${UNIVERSAL_DIR}/lib${PRODUCT_NAME}.a"
fi

mkdir -p "${UNIVERSAL_DIR}/resources"
find "${SYMROOT}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}" -name ${PRODUCT_NAME}*Resources.bundle -exec cp -rf {} "${UNIVERSAL_DIR}/resources" \;
