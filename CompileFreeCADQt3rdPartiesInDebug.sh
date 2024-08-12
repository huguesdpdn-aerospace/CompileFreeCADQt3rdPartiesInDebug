#!/bin/bash

UNKNOWN_ARGUMENT=0
INSTALL_PATH="${HOME}/FreeCADDebug"
QT_VERSION="last"
QT_FORCE_RECOMPILE=0
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
PACKAGE_MANAGER_COMMAND=""

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
    UNKNOWN_ARGUMENT=0
    argument="$(echo "${1}" | tr '[:upper:]' '[:lower:]' | sed 's/^--//g' | sed 's/^-//g')"
    if [ -z "${argument}" ]
    then
	UNKNOWN_ARGUMENT=0
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
	echo "[ERROR]: Unknown argument '${1}'"
	UNKNOWN_ARGUMENT=1
    fi
}

checkArguments()
{
    UNKNOWN_ARGUMENT=0
    if [ ! -d "${INSTALL_PATH}" ]
    then
	echo "[ERROR]: Invalid install path argument - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${QT_VERSION}" ]]
    then
	echo "[ERROR]: Invalid QT version - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${PS_VERSION}" ]]
    then
	echo "[ERROR]: Invalid PySide/Shiboken version - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${CN_VERSION}" ]]
    then
	echo "[ERROR]: Invalid Coin3D version - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${FC_VERSION}" ]]
    then
	echo "[ERROR]: Invalid FreeCAD version - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${QT_FORCE_RECOMPILE}" || ("${QT_FORCE_RECOMPILE}" != "0" && "${QT_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid QT recompile argument - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${PS_FORCE_RECOMPILE}" || ("${PS_FORCE_RECOMPILE}" != "0" && "${PS_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid PySide/Shiboken recompile argument - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${CN_FORCE_RECOMPILE}" || ("${CN_FORCE_RECOMPILE}" != "0" && "${CN_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid Coind3D recompile argument - See above errors"
	UNKNOWN_ARGUMENT=1
    elif [[ -z "${FC_FORCE_RECOMPILE}" || ("${FC_FORCE_RECOMPILE}" != "0" && "${FC_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid FreeCAD recompile argument - See above errors"
	UNKNOWN_ARGUMENT=1
    else
	UNKNOWN_ARGUMENT=0
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
	PACKAGE_MANAGER_COMMAND="apt-get install -y"
	PACKAGES_LIST=( "build-essential" "cmake" "valgrind" "python3" "emacs" "vi" "vim" "nano" )
    fi
}

installPackages()
{
    packages_list_to_install=()
    for package_to_install in ${PACKAGES_LIST[@]}
    do
	packages_list_to_install+=("${package_to_install}")
	if [[ ${#packages_list_to_install[@]} -ge ${PACKAGES_INSTALL_PER} ]]
	then
	    if ! sudo ${PACKAGE_MANAGER_COMMAND} ${packages_list_to_install[@]}
	    then
		echo "[ERROR]: Did not succeed to install packages ${packages_list_to_install[@]}"
	    fi
	    packages_list_to_install=()
	fi
    done
}

total_unknown_arguments=0
parseSingleArgument "${1}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${2}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${3}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${4}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${5}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${6}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${7}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${8}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
parseSingleArgument "${9}"
((total_unknown_arguments=total_unknown_arguments+UNKNOWN_ARGUMENT))
if [[ $total_unknown_arguments -gt 0 ]]
then
    echo "[ERROR]: Unknown arguments detected, stopping"
    exit 1
fi
if ! mkdir -p "${INSTALL_PATH}"
then
    echo "[ERROR]: Fail creating the install directory in ${INSTALL_PATH} - Stopping"
    exit 1
fi
determinePlatform
checkArguments
setPackagesToInstall
installPackages
