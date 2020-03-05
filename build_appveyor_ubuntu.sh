sudo apt-get -y install libxml2-dev libxml2 flex bison swig libpython3-all-dev python3 python3-numpy libfftw3-bin libfftw3-dev libfftw3-3 liblog4cpp5v5 liblog4cpp5-dev libboost1.65-dev libboost1.65 g++ git cmake autoconf libzip4 libzip-dev libglib2.0-dev libsigc++-2.0-dev libglibmm-2.4-dev doxygen qt5-default qtcreator qttools5-dev qttools5-dev-tools curl libvolk1-bin libvolk1-dev libvolk1.3 libgmp-dev libqt5svg5-dev libmatio-dev liborc-0.4-dev qtdeclarative5-dev

cd ~
git clone https://github.com/analogdevicesinc/libiio
cd libiio && mkdir build && cd build
cmake -DCMAKE_INSTALL_LIBDIR:STRING=lib -DINSTALL_UDEV_RULE:BOOL=OFF -DWITH_TESTS:BOOL=OFF -DWITH_DOC:BOOL=OFF -DWITH_IIOD:BOOL=OFF -DWITH_LOCAL_BACKEND:BOOL=OFF -DWITH_MATLAB_BINDINGS_API:BOOL=OFF ..
make
sudo make install


cd ~
git clone https://github.com/analogdevicesinc/libad9361-iio
cd libad9361-iio
mkdir build && cd build
cmake ..
make
sudo make install

sudo apt-get update
sudo apt-get install gnuradio

gr-iio
cd ~
git clone https://github.com/analogdevicesinc/gr-iio
cd gr-iio
git checkout upgrade-3.8
mkdir build && cd build
cmake ..
make
sudo make install

cd ~
git clone https://github.com/sigrokproject/libsigrok/
cd libsigrok
./autogen.sh
./configure --disable-all-drivers --enable-bindings --enable-cxx
make
sudo make install

cd ~
wget http://sigrok.org/download/source/libsigrokdecode/libsigrokdecode-0.4.1.tar.gz
tar -xzvf libsigrokdecode-0.4.1.tar.gz
cd libsigrokdecode-0.4.1
./configure
make
sudo make install


cd ~
git clone https://github.com/osakared/qwt
cd qwt
git checkout qwt-6.1-multiaxes
sed -i 's/\/usr\/local\/qwt-$$QWT_VERSION-svn/\/usr\/local/g' qwtconfig.pri
sed -i 's/QWT_CONFIG     += QwtDesigner/ /g' qwtconfig.pri

qmake qwt.pro
make
sudo make install


cd ~
wget https://downloads.sourceforge.net/project/qwtpolar/qwtpolar/1.1.1/qwtpolar-1.1.1.tar.bz2
tar xvjf qwtpolar-1.1.1.tar.bz2
cd qwtpolar-1.1.1
curl -o qwtpolar-qwt-6.1-compat.patch https://raw.githubusercontent.com/analogdevicesinc/scopy-flatpak/master/qwtpolar-qwt-6.1-compat.patch
patch -p1 < qwtpolar-qwt-6.1-compat.patch
sed -i 's/\/usr\/local\/qwtpolar-$$QWT_POLAR_VERSION/\/usr\/local/g' qwtpolarconfig.pri
sed -i 's/QWT_POLAR_CONFIG     += QwtPolarExamples/ /g' qwtpolarconfig.pri
sed -i 's/QWT_POLAR_CONFIG     += QwtPolarDesigner/ /g' qwtpolarconfig.pri
qmake qwtpolar.pro
make
sudo make install

