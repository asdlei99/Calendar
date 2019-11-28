#!/bin/bash
set -e

SOURCE_DIR=`pwd`
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi
TOOLS_DIR=${SOURCE_DIR}/Tools
cd ${SOURCE_DIR}
export RabbitCommon_DIR="${SOURCE_DIR}/RabbitCommon"

if [ "$BUILD_TARGERT" = "android" ]; then
    export ANDROID_SDK_ROOT=${TOOLS_DIR}/android-sdk
    export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-ndk
    if [ -n "$APPVEYOR" ]; then
        #export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
        export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-sdk/ndk-bundle
    fi
    #if [ "$TRAVIS" = "true" ]; then
        #export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    #fi
    export JAVA_HOME=${TOOLS_DIR}/android-studio/jre
    
    case $BUILD_ARCH in
        arm*)
            export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_armv7
            ;;
        x86)
        export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_x86
        ;;
    esac
    export PATH=${TOOLS_DIR}/apache-ant/bin:$JAVA_HOME/bin:$PATH
    export ANDROID_SDK=${ANDROID_SDK_ROOT}
    export ANDROID_NDK=${ANDROID_NDK_ROOT}
    if [ -z "${BUILD_TOOS_VERSION}" ]; then
        export BUILD_TOOS_VERSION="28.0.3"
    fi
fi

if [ "${BUILD_TARGERT}" = "unix" ]; then
    if [ "$DOWNLOAD_QT" = "TRUE" ]; then
        QT_DIR=${TOOLS_DIR}/Qt/${QT_VERSION}
        export QT_ROOT=${QT_DIR}/${QT_VERSION}/gcc_64
    else
        #source /opt/qt${QT_VERSION_DIR}/bin/qt${QT_VERSION_DIR}-env.sh
        export QT_ROOT=/opt/qt${QT_VERSION_DIR}
    fi
    export PATH=$QT_ROOT/bin:$PATH
    export LD_LIBRARY_PATH=$QT_ROOT/lib/i386-linux-gnu:$QT_ROOT/lib:$LD_LIBRARY_PATH
    export PKG_CONFIG_PATH=$QT_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
fi

if [ "$BUILD_TARGERT" != "windows_msvc" ]; then
    RABBIT_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBIT_MAKE_JOB_PARA" = "-j1" ];then
        RABBIT_MAKE_JOB_PARA=""
    fi
fi

if [ "$BUILD_TARGERT" = "windows_mingw" \
    -a -n "$APPVEYOR" ]; then
    export PATH=/C/Qt/Tools/mingw${TOOLCHAIN_VERSION}/bin:$PATH
fi
TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        export PKG_CONFIG=/c/msys64/mingw32/bin/pkg-config.exe
        RABBIT_BUILD_HOST="windows"
        if [ "$BUILD_TARGERT" = "android" ]; then
            ANDROID_NDK_HOST=windows-x86_64
            if [ ! -d $ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST} ]; then
                ANDROID_NDK_HOST=windows
            fi
            CONFIG_PARA="${CONFIG_PARA} -DCMAKE_MAKE_PROGRAM=make" #${ANDROID_NDK}/prebuilt/${ANDROID_NDK_HOST}/bin/make.exe"
        fi
        ;;
    Linux* | Unix*)
    ;;
    *)
    ;;
esac

export PATH=${QT_ROOT}/bin:$PATH
echo "PATH:$PATH"
echo "PKG_CONFIG:$PKG_CONFIG"
cd ${SOURCE_DIR}
if [ "${BUILD_TARGERT}" = "windows_msvc" ]; then
    ./tag.sh
fi
mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}

case ${BUILD_TARGERT} in
    windows_msvc)
        MAKE=nmake
        ;;
    windows_mingw)
        if [ "${RABBIT_BUILD_HOST}"="windows" ]; then
            MAKE="mingw32-make ${RABBIT_MAKE_JOB_PARA}"
        fi
        ;;
    *)
        MAKE="make ${RABBIT_MAKE_JOB_PARA}"
        ;;
esac

if [ -n "$appveyor_build_version" -a -z "$VERSION" ]; then
    export VERSION=$appveyor_build_version
fi
if [ -z "$VERSION" ]; then
    export VERSION="v0.3.1"
fi
if [ "${BUILD_TARGERT}" = "unix" ]; then
    cd $SOURCE_DIR
    if [ "${DOWNLOAD_QT}" != "TRUE" ]; then
        sed -i "s/export QT_VERSION_DIR=.*/export QT_VERSION_DIR=${QT_VERSION_DIR}/g" ${SOURCE_DIR}/debian/postinst
        sed -i "s/export QT_VERSION=.*/export QT_VERSION=${QT_VERSION}/g" ${SOURCE_DIR}/debian/preinst
        cat ${SOURCE_DIR}/debian/postinst
        cat ${SOURCE_DIR}/debian/preinst
    fi
    bash build_debpackage.sh ${QT_ROOT}

    sudo dpkg -i ../tasks_*_amd64.deb
    echo "test ......"
    ./test/test_linux.sh

    #因为上面 dpgk 已安装好了，所以不需要设置下面的环境变量
    #export LD_LIBRARY_PATH=`pwd`/debian/tasks/opt/Tasks/bin:`pwd`/debian/tasks/opt/Tasks/lib:${QT_ROOT}/bin:${QT_ROOT}/lib:$LD_LIBRARY_PATH
    
    cd debian/tasks/opt
    
    URL_LINUXDEPLOYQT=https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
    wget -c -nv ${URL_LINUXDEPLOYQT} -O linuxdeployqt.AppImage
    chmod a+x linuxdeployqt.AppImage

    cd Tasks
    ../linuxdeployqt.AppImage share/applications/*.desktop \
        -qmake=${QT_ROOT}/bin/qmake -appimage -no-copy-copyright-files -verbose

    # Create appimage install package
    #cp ../Tasks-${VERSION}-x86_64.AppImage .
    cp $SOURCE_DIR/Install/install.sh .
    cp $RabbitCommon_DIR/Install/install1.sh .
    ln -s Tasks-${VERSION}-x86_64.AppImage Tasks-x86_64.AppImage
    tar -czf Tasks_${VERSION}.tar.gz \
        Tasks-${VERSION}-x86_64.AppImage \
        Tasks-x86_64.AppImage \
        share \
        install.sh \
        install1.sh

    # Create update.xml
    MD5=`md5sum $SOURCE_DIR/../tasks_*_amd64.deb|awk '{print $1}'`
    echo "MD5:${MD5}"
    ./bin/TasksApp \
        -f "`pwd`/update_linux.xml" \
        -m "v0.3.1" \
        --md5 ${MD5}
    
    MD5=`md5sum Tasks_${VERSION}.tar.gz|awk '{print $1}'`
    ./Tasks-x86_64.AppImage \
        -f "`pwd`/update_linux_appimage.xml" \
        -m "v0.3.1" \
        --md5 ${MD5} \
        --url "https://github.com/KangLin/Tasks/releases/download/${VERSION}/Tasks_${VERSION}.tar.gz"
  
    if [ "$TRAVIS_TAG" != "" \
         -a "${QT_VERSION}" = "5.12.3" \
         -a "$DOWNLOAD_QT" != "TRUE" \
         -a -z "$GENERATORS" ]; then
        export UPLOADTOOL_BODY="Release Tasks-${VERSION}"
        #export UPLOADTOOL_PR_BODY=
        wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
        chmod u+x upload.sh
        ./upload.sh $SOURCE_DIR/../tasks_*_amd64.deb 
        ./upload.sh update_linux.xml update_linux_appimage.xml
        ./upload.sh Tasks_${VERSION}.tar.gz
    fi
    exit 0
fi

if [ -n "$GENERATORS" ]; then
    if [ -n "${STATIC}" ]; then
        CONFIG_PARA="-DBUILD_SHARED_LIBS=${STATIC}"
    fi
    if [ -n "${ANDROID_ARM_NEON}" ]; then
        CONFIG_PARA="${CONFIG_PARA} -DANDROID_ARM_NEON=${ANDROID_ARM_NEON}"
    fi
    if [ "${BUILD_TARGERT}" = "android" ]; then
        cmake -G"${GENERATORS}" ${SOURCE_DIR} ${CONFIG_PARA} \
            -DCMAKE_INSTALL_PREFIX=`pwd`/android-build \
            -DCMAKE_VERBOSE=ON \
            -DCMAKE_BUILD_TYPE=Release \
            -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5 \
            -DQt5Core_DIR=${QT_ROOT}/lib/cmake/Qt5Core \
            -DQt5Gui_DIR=${QT_ROOT}/lib/cmake/Qt5Gui \
            -DQt5Widgets_DIR=${QT_ROOT}/lib/cmake/Qt5Widgets \
            -DQt5Xml_DIR=${QT_ROOT}/lib/cmake/Qt5Xml \
            -DQt5Sql_DIR=${QT_ROOT}/lib/cmake/Qt5Sql \
            -DQt5Network_DIR=${QT_ROOT}/lib/cmake/Qt5Network \
            -DQt5Multimedia_DIR=${QT_ROOT}/lib/cmake/Qt5Multimedia \
            -DQt5LinguistTools_DIR=${QT_ROOT}/lib/cmake/Qt5LinguistTools \
            -DQt5AndroidExtras_DIR=${QT_ROOT}/lib/cmake/Qt5AndroidExtras \
            -DANDROID_PLATFORM=${ANDROID_API} \
            -DANDROID_ABI="${BUILD_ARCH}" \
            -DCMAKE_MAKE_PROGRAM=make \
            -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake 
    else
	    cmake -G"${GENERATORS}" ${SOURCE_DIR} ${CONFIG_PARA} \
		 -DCMAKE_INSTALL_PREFIX=`pwd`/install \
		 -DCMAKE_VERBOSE=ON \
		 -DCMAKE_BUILD_TYPE=Release \
		 -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5
    fi
    cmake --build . --config Release -- ${RABBIT_MAKE_JOB_PARA}
    cmake --build . --config Release --target install    
else
    if [ "ON" = "${STATIC}" ]; then
        CONFIG_PARA="CONFIG*=static"
    fi
    if [ "${BUILD_TARGERT}" = "android" ]; then
        ${QT_ROOT}/bin/qmake ${SOURCE_DIR} \
            "CONFIG+=release" ${CONFIG_PARA}

        $MAKE
        $MAKE install INSTALL_ROOT=`pwd`/android-build
    else
        ${QT_ROOT}/bin/qmake ${SOURCE_DIR} \
                "CONFIG+=release" ${CONFIG_PARA}\
                PREFIX=`pwd`/install
                
        $MAKE
        echo "$MAKE install ...."
        $MAKE install
    fi
fi

# Install package
if [ "${BUILD_TARGERT}" = "windows_msvc" ]; then
    if [ "${BUILD_ARCH}" = "x86" ]; then
        cp /C/OpenSSL-Win32/bin/libeay32.dll install/bin
        cp /C/OpenSSL-Win32/bin/ssleay32.dll install/bin
    elif [ "${BUILD_ARCH}" = "x64" ]; then
        cp /C/OpenSSL-Win64/bin/libeay32.dll install/bin
        cp /C/OpenSSL-Win64/bin/ssleay32.dll install/bin
    fi
    
    if [ -z "${STATIC}" ]; then
        "/C/Program Files (x86)/NSIS/makensis.exe" "Install.nsi"
        MD5=`md5sum Tasks-Setup-*.exe|awk '{print $1}'`
        echo "MD5:${MD5}"
        install/bin/TasksApp.exe -f "`pwd`/update_windows.xml" --md5 ${MD5} -m "v0.3.1"
        #cat update_windows.xml
    fi
fi

if [ "${BUILD_TARGERT}" = "android" ]; then
    ${QT_ROOT}/bin/androiddeployqt \
        --input `pwd`/App/android-libTasksApp.so-deployment-settings.json \
        --output `pwd`/android-build \
        --android-platform ${ANDROID_API} \
        --gradle \
        --sign ${RabbitCommon_DIR}/RabbitCommon.keystore rabbitcommon \
        --storepass ${STOREPASS}
    APK_FILE=`find . -name "android-build-release-signed.apk"`
    mv -f ${APK_FILE} $SOURCE_DIR/Tasks_${VERSION}.apk
    APK_FILE=$SOURCE_DIR/Tasks_${VERSION}.apk
    if [ "$TRAVIS_TAG" != "" \
         -a "$BUILD_ARCH"="armeabi-v7a" \
         -a "$QT_VERSION"="5.12.6" ]; then
    
        cp $SOURCE_DIR/Update/update_android.xml .
        MD5=`md5sum ${APK_FILE} | awk '{print $1}'`
        echo "MD5:${MD5}"
        sed -i "s/<VERSION>.*</<VERSION>${VERSION}</g" update_android.xml
        sed -i "s/<INFO>.*</<INFO>Release Tasks-${VERSION}</g" update_android.xml
        sed -i "s/<TIME>.*</<TIME>`date`</g" update_android.xml
        sed -i "s/<ARCHITECTURE>.*</<ARCHITECTURE>${BUILD_ARCH}</g" update_android.xml
        sed -i "s/<MD5SUM>.*</<MD5SUM>${MD5}</g" update_android.xml
        sed -i "s:<URL>.*<:<URL>https\://github.com/KangLin/Tasks/releases/download/${VERSION}/Tasks_${VERSION}.apk<:g" update_android.xml
    
        export UPLOADTOOL_BODY="Release Tasks-${VERSION}"
        #export UPLOADTOOL_PR_BODY=
        wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
        chmod u+x upload.sh
        ./upload.sh ${APK_FILE} 
        ./upload.sh update_android.xml
    fi
fi
