#!/usr/bin/env bash
#set -x
scriptName=$0
while getopts ":o:c:b:d:" args; do
  case $args in
    o) OUTPUT=$OPTARG;;
    c) CODENAME=$OPTARG;;
    b) BRANCH=$OPTARG;;
    d) DISTRO=$OPTARG;;
  esac
done
function helpMenu() {
  printf """
   ________________
        HELP
   ----------------

    bash ${scriptName} -o PATH-TO-YOUR-REPO-FILE -c CODENAME -b BRANCH -d DISTRO


    EXAMPLE:-
    bash ${scriptName} -o bhutuu.pwn.repo -c bhutuu -b main -d pwn-term\n"""
}

if [[ -z $OUTPUT || -z $CODENAME || -z $BRANCH || -z $DISTRO ]]; then
  helpMenu
  exit 1
fi


function addPermission() {
  chmod 0755 $1/DEBIAN
  if [[ -f $1/DEBIAN/postinst ]]; then
    chmod 0555 $1/DEBIAN/postinst
  fi
  if [[ -f $1/DEBIAN/preinst ]]; then
    chmod 0555 $1/DEBIAN/preinst
  fi
}

function AARCH64() {
  addPermission $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.aarch64.deb
  mv -v ${1}.aarch64.deb allDebFiles
}

function ARM() {
  addPermission $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.arm.deb
  mv -v ${1}.arm.deb allDebFiles
}

function I686() {
  addPermission $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.i686.deb
  mv -v ${1}.i686.deb allDebFiles
}

function X86_64() {
  addPermission $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.x86_64.deb
  mv -v ${1}.x86_64.deb allDebFiles
}
function ALL() {
  addPermission $1
  dpkg-deb -b $1
  mv ${1}.deb ${1}.all.deb
  mv -v ${1}.all.deb allDebFiles
  sed -i 's|Architecture: all|Architecture: aarch64|g' ${1}/DEBIAN/control
  AARCH64 $1
  sed -i 's|Architecture: aarch64|Architecture: arm|g' ${1}/DEBIAN/control
  ARM $1
  sed -i 's|Architecture: arm|Architecture: x86_64|g' ${1}/DEBIAN/control
  X86_64 $1
  sed -i 's|Architecture: x86_64|Architecture: i686|g' ${1}/DEBIAN/control
  I686 $1
  sed -i 's|Architecture: i686|Architecture: all|g' ${1}/DEBIAN/control
}

function main() {
  rm -rf allDebFiles >/dev/null 2>&1
  mkdir allDebFiles
  dirsincurrnt=($(ls))
  for i in ${dirsincurrnt[@]}; do
    checkDirf=$(tree $i | grep -w "DEBIAN")
    if [[ ! -z $checkDirf ]]; then
      architechture=$(cat $i/DEBIAN/control | grep "Architecture" | sed -e 's|Architecture: ||g')
      case $architechture in
        'all') ALL $i;;
        'aarch64') AARCH64 $i;;
        'arm') ARM $1;;
        'x86_64') X86_64 $1;;
        'i686') I686 $1;;
        *) printf "This architechture is not supported by our script\n"; exit 1;;
      esac
      if [ ! -f 'deb-apt-repo.py' ]; then
        wget -q https://raw.githubusercontent.com/BHUTUU/apt-repo-generator/main/deb-apt-repo.py
      fi
      python3 deb-apt-repo.py allDebFiles $OUTPUT $CODENAME $BRANCH
      sed -i "s|termux|$DISTRO|g" ${OUTPUT}/dists/${CODENAME}/Release
      cd ${OUTPUT}/dists/${CODENAME}
      gpg --clear-sign Release
      mv Release.asc InRelease
      sha256sum Release > Release.hash
    fi
  done
}
main
