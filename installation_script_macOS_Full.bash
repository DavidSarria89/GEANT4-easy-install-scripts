#!/bin/bash
set -e

#################
mkdir -p geant4 # directory were everything is built and installed
cd geant4
#############

########################## VARIABLES

##############  PROGRAMS' VERSIONS AND URLs : MAY CHANGE IN THE FUTURE
g4_version=10.4.p03
_g4_version=10.04.p03
folder_g4_version=Geant4-10.4.3
g4_url=("http://cern.ch/geant4-data/releases/geant4.${_g4_version}.tar.gz")

cmake_download_url=https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-Darwin-x86_64.tar.gz

xerces_w_ver=xerces-c-3.2.0
xerces_arc=${xerces_w_ver}.tar.gz
xerces_url=("http://archive.apache.org/dist/xerces/c/3/sources/${xerces_arc}")


####################################################

# getting CMake
echo "Attempt to download CMake"
rm -rf cmake
rm -rf cmake-3.14.3-Darwin-x86_64
rm -rf cmake-3.14.3-Darwin-x86_64.tar.gz
curl -L ${cmake_download_url} --output cmake-3.14.3-Darwin-x86_64.tar.gz
tar zxf cmake-3.14.3-Darwin-x86_64.tar.gz
mv cmake-3.14.3-Darwin-x86_64 cmake
rm -rf cmake-3.14.3-Darwin-x86_64.tar.gz
Echo "DONE"

# Parameters
core_nb=4

current_dir=${PWD}
base_dir=${PWD}

# CMake command
CMake_path=${base_dir}/cmake/CMake.app/Contents/bin/cmake

# Geant4
src_dir=${base_dir}/source_geant4.${_g4_version}/
build_dir=${base_dir}/geant4_build_${_g4_version}/
install_dir=${base_dir}/geant4_install_${_g4_version}/
geant4_lib_dir=${install_dir}/lib/${folder_g4_version}/

# XERCES-C

xercesc_build_dir=(${base_dir}/build_xercesc_g4_${_g4_version}/)
xercesc_install_dir=(${base_dir}/install_xercesc_g4_${_g4_version}/)
xercesc_inc_dir=(${xercesc_install_dir}/include)
xercesc_lib_dir=(${xercesc_install_dir}/lib64/libxerces-c-3.2.so)

########## Creating folders

mkdir -p ${build_dir} # -p will create only if it does not exist yet
mkdir -p ${src_dir}
mkdir -p ${install_dir}

mkdir -p ${xercesc_build_dir}
mkdir -p ${xercesc_install_dir}

#### XERCES-C (to be able to use GDML files)

## download xerces-c (for GDML)
echo "Attempt to download xerces-c"
curl -L ${xerces_url} --output ${xerces_w_ver}.tar.gz
tar zxf ${base_dir}/${xerces_arc}
rm -rf ${xerces_arc}
Echo "DONE"

xerces_src=${base_dir}/${xerces_w_ver}/

## install Qt5

Brew install qt


## compile and install xerces-c

cd ${xercesc_build_dir}

echo "build of xerces-c: Attempt to execute CMake..."

rm -rf CMakeCache.txt

${CMake_path} \
-DCMAKE_INSTALL_PREFIX=${xercesc_install_dir} \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INSTALL_LIBDIR=lib64 \
${xerces_src}
echo "... done"

echo "Attempt to compile and install xerces-c"

G4VERBOSE=1 make -j${core_nb}
make install

Cp -R ${xercesc_install_dir}/lib64/libxerces-c.so ${xercesc_install_dir}/lib64/libxerces-c-3.2.so
cd ${base_dir}
echo "... done"

#### GEANT4

## download Geant4
echo "Attempt to download GEANT4"
rm -rf ${src_dir}
Curl -L ${g4_url} --output geant4.${_g4_version}.tar.gz
tar zxf geant4.${_g4_version}.tar.gz
mv geant4.${_g4_version} ${src_dir}
rm -rf geant4.${_g4_version}.tar.gz
Echo "DONE"

## compile and install Geant4

cd ${build_dir}
rm -rf CMakeCache.txt

echo "build_geant4: Attempt to execute CMake"

${CMake_path} \
-DCMAKE_PREFIX_PATH=${xercesc_install_dir} \
-DCMAKE_INSTALL_PREFIX=${install_dir} \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_PREFIX_PATH="${xercesc_install_dir}/lib64/cmake/;/usr/local/opt/qt/lib/cmake/" \
-DGEANT4_BUILD_MULTITHREADED=ON \
-DGEANT4_BUILD_CXXSTD=c++11 \
-DGEANT4_INSTALL_DATA=ON \
-DGEANT4_USE_GDML=ON \
-DGEANT4_USE_G3TOG4=ON \
-DGEANT4_USE_QT=ON \
-DGEANT4_FORCE_QT4=OFF \
-DGEANT4_USE_XM=OFF \
-DGEANT4_USE_INVENTOR=OFF \
-DGEANT4_USE_RAYTRACER_X11=OFF \
-DGEANT4_USE_SYSTEM_CLHEP=OFF \
-DGEANT4_USE_SYSTEM_EXPAT=OFF \
-DGEANT4_USE_SYSTEM_ZLIB=OFF \
-DCMAKE_INSTALL_LIBDIR=lib \
-DXERCESC_INCLUDE_DIR=${xercesc_inc_dir} \
-DXERCESC_LIBRARY=${xercesc_lib_dir} \
../source_geant4.${_g4_version}/

echo "... Done"

echo "Attempt to compile and install Geant4"

G4VERBOSE=1 make -j${core_nb}

make install

cd ${base_dir}
echo "... Done"


#########################################################################
#########################################################################
#### set environment variables into '~/.bash_profile'

echo "Attempt to setup up environment variables..."

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# clean environment that was previously set by this script
first_line=`grep -n "## --> Added by Geant4 installation script" ~/.bash_profile | awk -F  ":" '{print $1}'`
echo $first_line
last_line=`grep -n "## <-- Added by Geant4 installation script" ~/.bash_profile | awk -F  ":" '{print $1}'`
echo $last_line

re='^[0-9]+$'
if [[ $first_line =~ $re ]] ; then # if $first_line is a number (i.e. it was found)
    if [[ $last_line =~ $re ]] ; then # if $last_line is a number (i.e. it was found)
        sed -i.bak "${first_line},${last_line}d" ~/.bash_profile # delete text in .bash_profile from first-line to last-line
    fi
fi

#
echo "## --> Added by Geant4 installation script" >> ~/.bash_profile

set_environement() {
    
    cd ${base_dir}
    
    if grep -Fxq "$1" ~/.bash_profile
    then
        echo -e "${GREEN}< source $1 > already set up in ~/.bash_profile.${NC}"
    else
        echo "    " >> ~/.bash_profile
        echo $1 >> ~/.bash_profile
        echo "______"
        echo -e "${GREEN}added ${RED}$1${GREEN} to ${RED}~/.bash_profile${GREEN} file.${NC}"
    fi
}

# Geant4 + data
set_environement "source ${install_dir}/bin/geant4.sh"
set_environement "export Geant4_DIR=${install_dir}/lib/Geant4-10.4.3/"
set_environement "export GEANT4_DIR=${install_dir}/lib/Geant4-10.4.3/"
set_environement "export GEANT4_INCLUDE_DIR=${install_dir}/include/"

# Qt5

set_environement "export PATH=\$PATH:/usr/local/opt/qt/include/"
set_environement "export PATH=\$PATH:/usr/local/opt/qt/lib/"
set_environement "export PATH=\$PATH:/usr/local/opt/qt/bin/"
set_environement "export QTDIR=/usr/local/opt/qt/"


# xerces-c
set_environement "export C_INCLUDE_PATH=\$C_INCLUDE_PATH:${xercesc_install_dir}/include/"
set_environement "export CPLUS_INCLUDE_PATH=\$CPLUS_INCLUDE_PATH:${xercesc_install_dir}/include/"
set_environement "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${xercesc_install_dir}/lib64/"
set_environement "export LIBRARY_PATH=\$LIBRARY_PATH:${xercesc_install_dir}/lib64/"
set_environement "export PATH=\$PATH:${xercesc_install_dir}/include/"

echo " " >> ~/.bash_profile
echo "## <-- Added by Geant4 installation script" >> ~/.bash_profile
echo "... Done"
echo -e "${RED}Please excecute command < ${GREEN}source ~/.bash_profile${RED} > or re-open a terminal for the system to be able to find the databases and libraries.${NC}"



#########################################################################
#########################################################################
#### set environment variables into '~/.bashrc'

echo "Attempt to setup up environment variables..."

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# clean environment that was previously set by this script
first_line=`grep -n "## --> Added by Geant4 installation script" ~/.bashrc | awk -F  ":" '{print $1}'`
echo $first_line
last_line=`grep -n "## <-- Added by Geant4 installation script" ~/.bashrc | awk -F  ":" '{print $1}'`
echo $last_line

re='^[0-9]+$'
if [[ $first_line =~ $re ]] ; then # if $first_line is a number (i.e. it was found)
    if [[ $last_line =~ $re ]] ; then # if $last_line is a number (i.e. it was found)
        sed -i.bak "${first_line},${last_line}d" ~/.bashrc # delete text in .bashrc from first-line to last-line
    fi
fi

#
echo "## --> Added by Geant4 installation script" >> ~/.bashrc

set_environement() {
    
    cd ${base_dir}
    
    if grep -Fxq "$1" ~/.bashrc
    then
        echo -e "${GREEN}< source $1 > already set up in ~/.bashrc.${NC}"
    else
        echo "    " >> ~/.bashrc
        echo $1 >> ~/.bashrc
        echo "______"
        echo -e "${GREEN}added ${RED}$1${GREEN} to ${RED}~/.bashrc${GREEN} file.${NC}"
    fi
}

# Geant4 + data
set_environement "source ${install_dir}/bin/geant4.sh"
set_environement "export Geant4_DIR=${install_dir}/lib/Geant4-10.4.3/"
set_environement "export GEANT4_DIR=${install_dir}/lib/Geant4-10.4.3/"
set_environement "export GEANT4_INCLUDE_DIR=${install_dir}/include/"

# Qt5

set_environement "export PATH=\$PATH:/usr/local/opt/qt/include/"
set_environement "export PATH=\$PATH:/usr/local/opt/qt/lib/"
set_environement "export PATH=\$PATH:/usr/local/opt/qt/bin/"
set_environement "export QTDIR=/usr/local/opt/qt/"


# xerces-c
set_environement "export C_INCLUDE_PATH=\$C_INCLUDE_PATH:${xercesc_install_dir}/include/"
set_environement "export CPLUS_INCLUDE_PATH=\$CPLUS_INCLUDE_PATH:${xercesc_install_dir}/include/"
set_environement "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${xercesc_install_dir}/lib64/"
set_environement "export LIBRARY_PATH=\$LIBRARY_PATH:${xercesc_install_dir}/lib64/"
set_environement "export PATH=\$PATH:${xercesc_install_dir}/include/"

echo " " >> ~/.bashrc
echo "## <-- Added by Geant4 installation script" >> ~/.bashrc
echo "... Done"
echo -e "${RED}Please excecute command < ${GREEN}source ~/.bashrc${RED} > or re-open a terminal for the system to be able to find the databases and libraries.${NC}"

