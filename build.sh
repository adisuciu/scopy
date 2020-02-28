set -e

export PATH=/bin:/usr/bin:/${MINGW_VERSION}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32
WORKDIR=${PWD}
echo BUILD_NO $BUILD_NO
JOBS=3

CC=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-gcc.exe
CXX=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-g++.exe
CMAKE_OPTS="
	-DCMAKE_C_COMPILER:FILEPATH=${CC} \
	-DCMAKE_CXX_COMPILER:FILEPATH=${CXX} \
	-DPKG_CONFIG_EXECUTABLE=/$MINGW_VERSION/bin/pkg-config.exe \
	-DCMAKE_PREFIX_PATH=/c/msys64/$MINGW_VERSION/lib/cmake \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	"

#	-DCMAKE_C_COMPILER=$ARCH-w64-mingw32-gcc.exe \
#	-DCMAKE_CXX_COMPILER=$ARCH-w64-mingw32-g++.exe \

SCOPY_CMAKE_OPTS="
	-G \"Unix\ Makefiles\"	\
	$RC_COMPILER_OPT \
	-DBREAKPAD_HANDLER=ON \
	-DGIT_EXECUTABLE=/c/Program\\ Files/Git/cmd/git.exe \
	-DPYTHON_EXECUTABLE=/$MINGW_VERSION/bin/python3.exe \
	"

PACMAN_SYNC_DEPS="
	mingw-w64-$ARCH-gcc \
	mingw-w64-$ARCH-boost \
	mingw-w64-$ARCH-python3 \
	mingw-w64-$ARCH-fftw \
	mingw-w64-$ARCH-libzip \
	mingw-w64-$ARCH-glibmm \
	mingw-w64-$ARCH-matio \
	mingw-w64-$ARCH-hdf5 \
	mingw-w64-$ARCH-orc \
"
PACMAN_REPO_DEPS="
	http://repo.msys2.org/mingw/$ARCH/mingw-w64-$ARCH-breakpad-git-r1680.70914b2d-1-any.pkg.tar.xz \
	http://repo.msys2.org/mingw/$ARCH/mingw-w64-$ARCH-qt5-5.13.2-1-any.pkg.tar.xz \
	http://repo.msys2.org/mingw/$ARCH/mingw-w64-$ARCH-libusb-1.0.21-2-any.pkg.tar.xz \
"

PRECOMPILED_DEPS="
	https://ci.appveyor.com/api/projects/analogdevicesinc/scopy-mingw-build-deps/artifacts/scopy-$MINGW_VERSION-build-deps.tar.xz?branch=disable_gr&job=Environment: MINGW_VERSION=$MINGW_VERSION, ARCH=$ARCH; \
	https://ci.appveyor.com/api/projects/analogdevicesinc/scopy-mingw-build-deps/artifacts/scopy-$MINGW_VERSION-build-deps.tar.xz?branch=disable_gr&job=Environment: MINGW_VERSION=$MINGW_VERSION, ARCH=$ARCH; \
	http://swdownloads.analog.com/cse/build/windres.exe.gz \

"
Field_Separator=$IFS
IFS=';'
for val in $PRECOMPILED_DEPS;
do
	echo $val !!! 
	wget \"$val\"
done
IFS=$Field_Separator




if [ ${ARCH} == "i686" ]
then
	RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=/c/windres.exe"
else
	RC_COMPILER_OPT=""
fi

OLD_PATH=$PATH
DEST_FOLDER=scopy_$ARCH_BIT
BUILD_FOLDER=build_$ARCH_BIT
DEBUG_FOLDER=debug_$ARCH_BIT

PATH=/c/msys64/$MINGW_VERSION/bin:$PATH

# Remove dependencies that prevent us from upgrading to GCC 6.2
pacman -Rs --noconfirm \
	mingw-w64-${ARCH}-gcc-ada \
	mingw-w64-${ARCH}-gcc-fortran \
	mingw-w64-${ARCH}-gcc-libgfortran \
	mingw-w64-${ARCH}-gcc-objc
# Remove existing file that causes GCC install to fail
rm /mingw32/etc/gdbinit /mingw64/etc/gdbinit
# Update to GCC 6.2 and install build-time dependencies
pacman --force --noconfirm -Sy \
	mingw-w64-${ARCH}-gcc \
	mingw-w64-${ARCH}-cmake \
	autoconf \
	automake-wrapper

# Update to GCC 6.2 and install dependencies
pacman --noconfirm -Sy $PACMAN_SYNC_DEPS
pacman --noconfirm -U  $PACMAN_REPO_DEPS

# Install pre-compiled libraries

wget "https://ci.appveyor.com/api/projects/analogdevicesinc/scopy-mingw-build-deps/artifacts/scopy-$MINGW_VERSION-build-deps.tar.xz?branch=disable_gr&job=Environment: MINGW_VERSION=$MINGW_VERSION, ARCH=$ARCH" -O /c/scopy-$MINGW_VERSION-build-deps.tar.xz
cd /c ;
tar xJf scopy-$MINGW_VERSION-build-deps.tar.xz

wget "https://ci.appveyor.com/api/projects/adisuciu/gnuradio/artifacts/gnuradio-$MINGW_VERSION.tar.xz?branch=ming-3.8&job=Environment: MINGW_VERSION=$MINGW_VERSION, ARCH=$ARCH" -O /c/gnuradio-$MINGW_VERSION.tar.xz
cd /c ; tar xJf gnuradio-$MINGW_VERSION.tar.xz


# Download a 32-bit version of windres.exe
cd /c
wget http://swdownloads.analog.com/cse/build/windres.exe.gz
gunzip windres.exe.gz

# Hack: Qt5Qml CMake script throws errors when loading its plugins. So let's just drop those plugins.
rm -f /$MINGW_VERSION/lib/cmake/Qt5Qml/*Factory.cmake

/$MINGW_VERSION/bin/python3.exe --version
mkdir /c/$BUILD_FOLDER
cd /c/$BUILD_FOLDER
cmake  $CMAKE_OPTS $SCOPY_CMAKE_OPTS /c/projects/scopy

cd /c/$BUILD_FOLDER/resources 
sed -i  's/^\(FILEVERSION .*\)$/\1,'$BUILD_NO'/' properties.rc
cat properties.rc
cd /c/build_$ARCH_BIT && make -j3

# Copy the dependencies

mkdir c:\$DEST_FOLDER
copy c:\$BUILD_FOLDER\Scopy.exe c:\$DEST_FOLDER\
copy c:\$BUILD_FOLDER\qt.conf c:\$DEST_FOLDER\

c:\msys64\$MINGW_VERSION\bin\windeployqt.exe --dir c:\$DEST_FOLDER --release --no-system-d3d-compiler --no-compiler-runtime --no-quick-import --opengl --printsupport c:\$BUILD_FOLDER\Scopy.exe
cp -r /c/projects/scopy/resources/decoders  /c/$DEST_FOLDER/

tar -C /c/$DEST_FOLDER --strip-components=3 -xJf /c/scopy-$MINGW_VERSION-build-deps.tar.xz msys64/$MINGW_VERSION/bin
cd /$MINGW_VERSION/bin ; cp -r libmatio-*.dll libhdf5-*.dll libszip*.dll libpcre*.dll libdouble-conversion*.dll libwinpthread-*.dll libgcc_*.dll libstdc++-*.dll libboost_{system,filesystem,atomic,program_options,regex,thread}-*.dll libglib-*.dll libintl-*.dll libiconv-*.dll libglibmm-2.*.dll libgmodule-2.*.dll libgobject-2.*.dll libffi-*.dll libsigc-2.*.dll libfftw3f-*.dll libicu{in,uc,dt}[!d]*.dll zlib*.dll libharfbuzz-*.dll libfreetype-*.dll libbz2-*.dll libpng16-*.dll libgraphite2.dll libjpeg-*.dll libsqlite3-*.dll libwebp-*.dll libxml2-*.dll liblzma-*.dll libxslt-*.dll libzip*.dll libpython3.*.dll libgnutls*.dll libnettle*.dll libhogweed*.dll libgmp*.dll libidn*.dll libp11*.dll libtasn*.dll libunistring*.dll libusb-*.dll libzstd*.dll libgnuradio-*.dll /$MINGW_VERSION/lib/python3.* libiio*.dll libvolk*.dll liblog4cpp*.dll libad9361*.dll liborc*.dll /c/$DEST_FOLDER/

mkdir C:\scopy_$ARCH_BIT\.debug
#/$MINGW_VERSION/bin/objcopy -v --only-keep-debug /c/$DEST_FOLDER/Scopy.exe /c/$DEST_FOLDER/.debug/Scopy.exe.debug
dump_syms /c/$DEST_FOLDER/Scopy.exe > /c/$DEST_FOLDER/Scopy.exe.sym
#/c/msys64/$MINGW_VERSION/bin/strip.exe --strip-debug --strip-unneeded /c/$DEST_FOLDER/Scopy.exe
#/c/msys64/$MINGW_VERSION/bin/objcopy.exe -v --add-gnu-debuglink=/c/$DEST_FOLDER/.debug/Scopy.exe.debug /c/$DEST_FOLDER/Scopy.exe
mkdir C:\$DEBUG_FOLDER
mv C:\$DEST_FOLDER\Scopy.exe.sym C:\$DEBUG_FOLDER
mv C:\$DEST_FOLDER\.debug C:\$DEBUG_FOLDER

