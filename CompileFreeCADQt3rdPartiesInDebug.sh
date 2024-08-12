#!/bin/bash

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
if [[ -d "${HOME}/.local/share" ]]
then
    CACHE_PATH="${HOME}/.local/share/FreeCADDebug"
else
    CACHE_PATH="${HOME}/.FreeCADDebug"
fi
INSTALL_PATH="${HOME}/FreeCADDebug"
QT_VERSION="last"
QT_FORCE_RECOMPILE=0
QT_PATH=""
QT_CURRENT_TAG=""
PS_VERSION="last"
PS_FORCE_RECOMPILE=0
CN_VERSION="last"
CN_FORCE_RECOMPILE=0
FC_VERSION="last"
FC_FORCE_RECOMPILE=0
PLATFORM_NAME=""
PLATFORM_VERSION=""
PACKAGES_LIST=()
PACKAGES_INSTALL_PER=8
PACKAGE_MANAGER_COMMAND_UPDATE=""
PACKAGE_MANAGER_COMMAND_INSTALL=""

parseVersionOn3Digits()
{
    version="${1}"
    if [[ "$(echo "${version}" | cut -c 1)" == "v" || "$(echo "${version}" | cut -c 1)" == "V" ]]
    then
	version="$(echo "${version}" | cut -c 2-)"
    fi
    version="$(echo "${version}" | tr ';' '.' | tr ',' '.' | tr ':' '.' | tr '/' '.' | tr '-' '.' | tr '_' '.')"
    if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    then
	echo "${version}"
    else
	echo ""
    fi
}

parseSingleArgument()
{
    argument="$(echo "${1}" | tr '[:upper:]' '[:lower:]' | sed 's/^--//g' | sed 's/^-//g')"
    if [ -z "${argument}" ]
    then
	argument="${argument}"
    elif [[ "${argument}" =~ ^install-path=.* ]]
    then
	TEMP_PATH_TO_TEST="$(echo "${argument}" | cut -c 14-)"
	if [ -z "${TEMP_PATH_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a path after the --install-path , like so: --install-path=/my/path/to"
	elif [ -d "${TEMP_PATH_TO_TEST}" ]
	then
	    echo "[INFO ]: Setting install path to ${TEMP_PATH_TO_TEST}"
	    INSTALL_PATH="${TEMP_PATH_TO_TEST}"
	else
	    echo "[INFO ]: Creating ${TEMP_PATH_TO_TEST} directory since it seems it does not exist ..."
	    mkdir -p "${TEMP_PATH_TO_TEST}" > /dev/null 2>&1
	    if [ -d "${TEMP_PATH_TO_TEST}" ]
	    then
		echo "[INFO ]: Setting install path to ${TEMP_PATH_TO_TEST}"
		INSTALL_PATH="${TEMP_PATH_TO_TEST}"
	    else
		echo "[ERROR]: Did not succeed to create ${TEMP_PATH_TO_TEST}"
		INSTALL_PATH=""
	    fi
	fi
    elif [[ "${argument}" =~ ^qt-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 12-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a QT version after the --qt-version , like so: --qt-version=6.3.2"
	    QT_VERSION=""
	else
	    TEMP_VERSION_TO_TEST="$(parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}")"
	    if [ -z "${TEMP_VERSION_TO_TEST}" ]
	    then
		echo "[ERROR]: QT version provided is invalid - Must be on 3 numbers separated by points, like: --qt-version=6.3.2"
		QT_VERSION=""
	    else
		QT_VERSION="${TEMP_VERSION_TO_TEST}"
	    fi
	fi
    elif [[ "${argument}" =~ ^ps-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 12-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a PySide/Shiboken version after the --ps-version , like so: --ps-version=6.1.7"
	    PS_VERSION=""
	else
	    TEMP_VERSION_TO_TEST="$(parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}")"
	    if [ -z "${TEMP_VERSION_TO_TEST}" ]
	    then
		echo "[ERROR]: PySide/Shiboken version provided is invalid - Must be on 3 numbers separated by points, like: --ps-version=6.1.7"
		PS_VERSION=""
	    else
		PS_VERSION="${TEMP_VERSION_TO_TEST}"
	    fi
	fi
    elif [[ "${argument}" =~ ^c3d-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 13-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a Coin3D version after the --c3d-version , like so: --c3d-version=3.1.0"
	    CN_VERSION=""
	else
	    TEMP_VERSION_TO_TEST="$(parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}")"
	    if [ -z "${TEMP_VERSION_TO_TEST}" ]
	    then
		echo "[ERROR]: Coind3D version provided is invalid - Must be on 3 numbers separated by points, like: --c3d-version=3.1.0"
		CN_VERSION=""
	    else
		CN_VERSION="${TEMP_VERSION_TO_TEST}"
	    fi
	fi
    elif [[ "${argument}" =~ ^fc-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 12-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a FreeCAD version after the --fc-version , like so: --fc-version=0.21.2"
	    FC_VERSION=""
	else
	    TEMP_VERSION_TO_TEST="$(parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}")"
	    if [ -z "${TEMP_VERSION_TO_TEST}" ]
	    then
		echo "[ERROR]: FreeCAD version provided is invalid - Must be on 3 numbers separated by points, like: --fc-version=0.21.2"
		FC_VERSION=""
	    else
		FC_VERSION="${TEMP_VERSION_TO_TEST}"
	    fi
	fi
    elif [[ "${argument}" =~ ^qt-force-recompile.* ]]
    then
	QT_FORCE_RECOMPILE=1
    elif [[ "${argument}" =~ ^ps-force-recompile.* ]]
    then
	PS_FORCE_RECOMPILE=1
    elif [[ "${argument}" =~ ^c3d-force-recompile.* ]]
    then
	CN_FORCE_RECOMPILE=1
    elif [[ "${argument}" =~ ^fc-force-recompile.* ]]
    then
	FC_FORCE_RECOMPILE=1
    else
	echo "[ERROR]: Unknown argument '${1}' - Please check official documentation"
	kill -s TERM $$

    fi
}

checkInstallPath()
{
    INSTALL_PATH=${INSTALL_PATH%/}
    if [[ "$(echo "${INSTALL_PATH}" | cut -c 1)" == "." || "$(echo "${INSTALL_PATH}" | cut -c 1)" == "~" ]]
    then
	INSTALL_PATH=""
	echo "[ERROR]: You are forbidden to use a relative install path - Please provide the full path"
    fi
    if ! mkdir -p "${INSTALL_PATH}"
    then
	echo "[ERROR]: Fail creating the install directory in ${INSTALL_PATH} - Stopping"
	exit 1
    fi
}

checkArguments()
{
    if [ ! -d "${INSTALL_PATH}" ]
    then
	echo "[ERROR]: Invalid install path argument - See above errors"
    elif [[ -z "${QT_VERSION}" ]]
    then
	echo "[ERROR]: Invalid QT version - See above errors"
    elif [[ -z "${PS_VERSION}" ]]
    then
	echo "[ERROR]: Invalid PySide/Shiboken version - See above errors"
    elif [[ -z "${CN_VERSION}" ]]
    then
	echo "[ERROR]: Invalid Coin3D version - See above errors"
    elif [[ -z "${FC_VERSION}" ]]
    then
	echo "[ERROR]: Invalid FreeCAD version - See above errors"
    elif [[ -z "${QT_FORCE_RECOMPILE}" || ("${QT_FORCE_RECOMPILE}" != "0" && "${QT_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid QT recompile argument - See above errors"
    elif [[ -z "${PS_FORCE_RECOMPILE}" || ("${PS_FORCE_RECOMPILE}" != "0" && "${PS_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid PySide/Shiboken recompile argument - See above errors"
    elif [[ -z "${CN_FORCE_RECOMPILE}" || ("${CN_FORCE_RECOMPILE}" != "0" && "${CN_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid Coind3D recompile argument - See above errors"
    elif [[ -z "${FC_FORCE_RECOMPILE}" || ("${FC_FORCE_RECOMPILE}" != "0" && "${FC_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid FreeCAD recompile argument - See above errors"
    else
	mkdir -p "${CACHE_PATH}"	
    fi
}

gitPullMyOwnRepo()
{
    if [ -f "${CACHE_PATH}/LAST_GIT_PULL" ]
    then
	find "${CACHE_PATH}" -type f -name LAST_GIT_PULL -mtime +60 -delete
    fi
    if [ ! -f "${CACHE_PATH}/LAST_GIT_PULL" ]
    then
	if [ -d "${SCRIPT_DIRECTORY}/.git" ]
	then
	    cd "${SCRIPT_DIRECTORY}"
	    echo "[INFO ]: Updating this script ... a GIT authentication may be require:"
            if git pull
	    then
		touch "${CACHE_PATH}/LAST_GIT_PULL"
		echo "[INFO ]: You must restart this script as you just did since we just update this script."
		kill -s TERM $$
	    fi
	fi
    fi
}

determinePlatform()
{
    PLATFORM_NAME="$(grep '^NAME=' /etc/os-release | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]' | cut -c 6-)"
    PLATFORM_VERSION="$(grep '^VERSION_ID=' /etc/os-release | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]' | cut -c 12-)"
}

setPackagesToInstall()
{
    if [[ "${PLATFORM_NAME}" == "ubuntu" && "${PLATFORM_VERSION}" =~ 24.* ]]
    then
	PACKAGE_MANAGER_COMMAND_UPDATE="apt-get update"
	PACKAGE_MANAGER_COMMAND_INSTALL="apt-get install -y"
	PACKAGES_LIST=( "build-essential" "cmake" "valgrind" "python3" "ninja-build" "git" "perl")
    else
	PACKAGE_MANAGER_COMMAND_UPDATE=""
	PACKAGE_MANAGER_COMMAND_INSTALL=""
	PACKAGES_LIST=()
	echo "[ERROR]: Your platform is not managed by this script - Your platform: [${PLATFORM_NAME}] and version [${PLATFORM_VERSION}]"
	echo "[ERROR]: If you wish, you can request its implementation by:"
	echo "[ERROR]: creating an issue on GIT: https://github.com/huguesdpdn-aerospace/CompileFreeCADQt3rdPartiesInDebug/issues"
	echo "[ERROR]:     on the FreeCAD forum: https://forum.freecad.org/viewforum.php?f=4&sid=492b04c6ea9185bc2a97f3115ce31dac by tagging @huguesdpdn-aerospace"
	kill -s TERM $$
    fi
}

installPackages()
{
    if [ -f "${CACHE_PATH}/INSTALL_OK" ]
    then
	find "${CACHE_PATH}" -type f -name INSTALL_OK -mtime +60 -delete
    fi
    if [ ! -f "${CACHE_PATH}/INSTALL_OK" -a -n "${PACKAGE_MANAGER_COMMAND_INSTALL}" ]
    then
	sudo ${PACKAGE_MANAGER_COMMAND_UPDATE}
	packages_list_to_install=()
	for package_to_install in ${PACKAGES_LIST[@]}
	do
	    packages_list_to_install+=("${package_to_install}")
	    if [[ ${#packages_list_to_install[@]} -ge ${PACKAGES_INSTALL_PER} ]]
	    then
		if ! sudo ${PACKAGE_MANAGER_COMMAND_INSTALL} ${packages_list_to_install[@]}
		then
		    echo "[ERROR]: Did not succeed to install packages ${packages_list_to_install[@]} - Check above errors"
		    kill -s TERM $$
		fi
		packages_list_to_install=()
	    fi
	done
	if [[ ${#packages_list_to_install[@]} -gt 0 ]]
	then
	    if ! sudo ${PACKAGE_MANAGER_COMMAND_INSTALL} ${packages_list_to_install[@]}
	    then
		echo "[ERROR]: Did not succeed to install packages ${packages_list_to_install[@]} - Check above errors"
		kill -s TERM $$
	    fi
	    packages_list_to_install=()
	fi
	touch "${CACHE_PATH}/INSTALL_OK"
    fi
}

downloadQT()
{
    cd "${INSTALL_PATH}"
    QT_PATH="${INSTALL_PATH}/QT_${QT_VERSION}"
    if [ ! -d "${QT_PATH}" ]
    then
	mkdir -p "${QT_PATH}"
    fi
    if [ -d "${QT_PATH}" ]
    then
	cd "${QT_PATH}"
	if [ ! -d ".git" ]
	then
	    cd "${INSTALL_PATH}"
	    git clone https://code.qt.io/qt/qt5.git "${QT_PATH}"
	    cd "${QT_PATH}"
	fi
	if ! git describe --exact-match --tags > /dev/null 2>&1
	then
	    QT_CURRENT_TAG=""
	else
	    QT_CURRENT_TAG="$(git describe --exact-match --tags)"
	fi
	if [[ "${QT_CURRENT_TAG}" != "v${QT_VERSION}" ]]
	then
	    TAGS_LIST=( $(git --no-pager tag --list | grep --color=no -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | tr '\n' ' ') )
	    TAG_VERSION=""
	    for git_tag in ${TAGS_LIST[@]}
	    do
		if [[ "${git_tag}" == "v${QT_VERSION}" ]]
		then
		    TAG_VERSION="${git_tag}"
		fi
	    done
	    if [[ -z "${TAG_VERSION}" ]]
	    then
		echo "[ERROR]: Tag version '${QT_VERSION}' not found in QT repository - Cleaning... and aborting"
		cd "${INSTALL_PATH}"
		rm -rf "${QT_PATH}"
		kill -s TERM $$
	    fi
	    if git checkout "${TAG_VERSION}"
	    then
		QT_CURRENT_TAG="${TAG_VERSION}"
	    else
		echo "[ERROR]: Fail switching on tag '${TAG_VERSION}' - Cleaning... and aborting"
		cd "${INSTALL_PATH}"
		rm -rf "${QT_PATH}"
		kill -s TERM $$
	    fi
	fi
	if [ -f "init-repository" ]
	then
	    chmod +x "init-repository"
	    if ! perl init-repository -f
	    then
		echo "[ERROR]: Failure while downloading all QT submodules ... will retry in 5 seconds - Check your internet connection"
		sleep 5
		if ! perl init-repository -f
		then
		    echo "[ERROR]: Failure while downloading all QT submodules ... will retry in 60 seconds - Check your internet connection"
		    sleep 60
		    if ! perl init-repository -f
		    then
			echo "[ERROR]: Failure while downloading all QT submodules ... will retry in 5 minutes - Check your internet connection"
			sleep 300
			if ! perl init-repository -f
			then
			    echo "[ERROR]: Failure while downloading all QT submodules ... will retry in 1 hour - Check your internet connection"
			    sleep 3600
			    if ! perl init-repository -f
			    then
				echo "[ERROR]: Failure while downloading all QT submodules ... too many retries - Check your internet connection"
				echo "[ERROR]: Do not worry, what have alredy been downloaded will be kept"
				echo "[ERROR]: Just launch this script again and it will resume download where it has stopped" 
				kill -s TERM $$
			    fi
			fi
		    fi
		fi
	    fi
	fi
    fi
}

parseSingleArgument "${1}"
parseSingleArgument "${2}"
parseSingleArgument "${3}"
parseSingleArgument "${4}"
parseSingleArgument "${5}"
parseSingleArgument "${6}"
parseSingleArgument "${7}"
parseSingleArgument "${8}"
parseSingleArgument "${9}"
gitPullMyOwnRepo
determinePlatform
checkInstallPath
checkArguments
setPackagesToInstall
installPackages
downloadQT
