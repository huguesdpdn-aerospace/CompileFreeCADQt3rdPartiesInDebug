#!/bin/bash

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_ARG0="${0}"
SCRIPT_ARG1="${1}"
SCRIPT_ARG2="${2}"
SCRIPT_ARG3="${3}"
SCRIPT_ARG4="${4}"
SCRIPT_ARG5="${5}"
SCRIPT_ARG6="${6}"
SCRIPT_ARG7="${7}"
SCRIPT_ARG8="${8}"
SCRIPT_ARG9="${9}"
if [[ -d "${HOME}/.local/share" ]]
then
    CACHE_PATH="${HOME}/.local/share/FreeCADDebug"
else
    CACHE_PATH="${HOME}/.FreeCADDebug"
fi
INSTALL_PATH="${HOME}/FreeCADDebug"
QT_VERSION_3NUMBERS="last-stable"
QT_VERSION_OFFSET=0
QT_FORCE_RECOMPILE=0
QT_PATH=""
QT_CURRENT_TAG=""
PS_VERSION_3NUMBERS="last-stable"
PS_VERSION_OFFSET=0
PS_FORCE_RECOMPILE=0
CN_VERSION_3NUMBERS="last-stable"
CN_VERSION_OFFSET=0
CN_FORCE_RECOMPILE=0
FC_VERSION_3NUMBERS="last-stable"
FC_VERSION_OFFSET=0
FC_FORCE_RECOMPILE=0
PLATFORM_NAME=""
PLATFORM_VERSION=""
PACKAGES_LIST=()
PACKAGES_INSTALL_PER=8
PACKAGE_MANAGER_COMMAND_UPDATE=""
PACKAGE_MANAGER_COMMAND_UPGRADE=""
PACKAGE_MANAGER_COMMAND_INSTALL=""

parseVersionOn3Digits()
{
    version="$(echo "${1}" | tr -d ' ' | tr '[:upper:]' '[:lower:]' | sed -r 's/-alpha[0-9]+//g' | sed -r 's/-beta[0-9]+//g' | sed -r 's/-rc[0-9]+//g' )"
    if [[ "$(echo "${version}" | cut -c 1)" == "v" ]]
    then
	version="$(echo "${version}" | cut -c 2-)"
    fi

    VERSION_3NUMBERS=""
    VERSION_OFFSET=0
    if [[ -n "$(echo "${version}" | grep --color=no -oE '[-+][0-9]+$')" ]]
    then
	VERSION_OFFSET="$(echo "${version}" | grep --color=no -oE '[-+][0-9]+$')"
	((VERSION_OFFSET=VERSION_OFFSET+0))
    fi
    if   [[ "$(echo "${version}" | cut -c 1-4)" == "pull" ]]
    then
	VERSION_3NUMBERS="pull"
	VERSION_OFFSET=0
    elif [[ "$(echo "${version}" | cut -c 1-12)" == "first-stable" || "$(echo "${version}" | cut -c 1-13)" == "first-release" ]]
    then
	VERSION_3NUMBERS="first-stable"
    elif [[ "$(echo "${version}" | cut -c 1-11)" == "last-stable" || "$(echo "${version}" | cut -c 1-12)" == "last-release" ]]
    then
	VERSION_3NUMBERS="last-stable"
    elif [[ "$(echo "${version}" | cut -c 1-7)" == "current" || "$(echo "${version}" | cut -c 1-6)" == "latest" || "$(echo "${version}" | cut -c 1-3)" == "dev" ]]
    then
	VERSION_3NUMBERS="current"
	VERSION_OFFSET=0
    else
	VERSION_3NUMBERS="$(echo "${version}" | tr ';' '.' | tr ',' '.' | tr ':' '.' | tr '/' '.' | tr '-' '.' | tr '+' '.' | tr '_' '.')"
	if [[ "${VERSION_3NUMBERS}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.* ]]
	then
	    VERSION_3NUMBERS="$(echo "${VERSION_3NUMBERS}" | grep --color=no -oE '^[0-9]+\.[0-9]+\.[0-9]+')"
	elif [[ "${VERSION_3NUMBERS}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
	then
	    VERSION_3NUMBERS="${VERSION_3NUMBERS}"
	    VERSION_OFFSET=0
	elif [[ "${VERSION_3NUMBERS}" =~ ^[0-9]+\.[0-9]+\.[0-9]+.* ]]
	then
	    VERSION_3NUMBERS="${VERSION_3NUMBERS}"
	elif [[ "${VERSION_3NUMBERS}" =~ ^[0-9]+\.[0-9]+$ ]]
	then
	    VERSION_3NUMBERS="${VERSION_3NUMBERS}.0"
	    VERSION_OFFSET=0
	elif [[ "${VERSION_3NUMBERS}" =~ ^[0-9]+\.[0-9]+[-+].* ]]
	then
	    VERSION_3NUMBERS="${VERSION_3NUMBERS}.0"
	else
	    VERSION_3NUMBERS=""
	fi
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
	TEMP_PATH_TO_TEST="$(echo "${1}" | cut -d '=' -f 2)"
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
	    QT_VERSION_3NUMBERS=""
	    QT_VERSION_OFFSET=0
	else
	    VERSION_3NUMBERS=""
	    parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}"
	    if [ -z "${VERSION_3NUMBERS}" ]
	    then
		echo "[ERROR]: QT version provided is invalid - Must be on 3 numbers separated by points, like: --qt-version=6.3.2"
		QT_VERSION_3NUMBERS=""
		QT_VERSION_OFFSET=0
	    else
		QT_VERSION_3NUMBERS="${VERSION_3NUMBERS}"
		QT_VERSION_OFFSET=${VERSION_OFFSET}
	    fi
	fi
    elif [[ "${argument}" =~ ^ps-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 12-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a PySide/Shiboken version after the --ps-version , like so: --ps-version=6.1.7"
	    PS_VERSION_3NUMBERS=""
	    PS_VERSION_OFFSET=0
	else
	    VERSION_3NUMBERS=""
	    parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}"
	    if [ -z "${VERSION_3NUMBERS}" ]
	    then
		echo "[ERROR]: PySide/Shiboken version provided is invalid - Must be on 3 numbers separated by points, like: --ps-version=6.1.7"
		PS_VERSION_3NUMBERS=""
		PS_VERSION_OFFSET=0
	    else
		PS_VERSION_3NUMBERS="${VERSION_3NUMBERS}"
		PS_VERSION_OFFSET=${VERSION_OFFSET}
	    fi
	fi
    elif [[ "${argument}" =~ ^c3d-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 13-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a Coin3D version after the --c3d-version , like so: --c3d-version=3.1.0"
	    CN_VERSION_3NUMBERS=""
	    CN_VERSION_OFFSET=0
	else
	    parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}"
	    if [ -z "${VERSION_3NUMBERS}" ]
	    then
		echo "[ERROR]: Coind3D version provided is invalid - Must be on 3 numbers separated by points, like: --c3d-version=3.1.0"
		CN_VERSION_3NUMBERS=""
		CN_VERSION_OFFSET=0
	    else
		CN_VERSION_3NUMBERS="${VERSION_3NUMBERS}"
		CN_VERSION_OFFSET=${VERSION_OFFSET}
	    fi
	fi
    elif [[ "${argument}" =~ ^fc-version=.* ]]
    then
	TEMP_VERSION_TO_TEST="$(echo "${argument}" | cut -c 12-)"
	if [ -z "${TEMP_VERSION_TO_TEST}" ]
	then
	    echo "[ERROR]: You must provide a FreeCAD version after the --fc-version , like so: --fc-version=0.21.2"
	    FC_VERSION_3NUMBERS=""
	    FC_VERSION_OFFSET=0
	else
	    parseVersionOn3Digits "${TEMP_VERSION_TO_TEST}"
	    if [ -z "${VERSION_3NUMBERS}" ]
	    then
		echo "[ERROR]: FreeCAD version provided is invalid - Must be on 3 numbers separated by points, like: --fc-version=0.21.2"
		FC_VERSION_3NUMBERS=""
		FC_VERSION_OFFSET=0
	    else
		FC_VERSION_3NUMBERS="${VERSION_3NUMBERS}"
		FC_VERSION_OFFSET="${VERSION_OFFSET}"
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
	kill -s TERM $$
    elif [[ -z "${QT_VERSION_3NUMBERS}" ]]
    then
	echo "[ERROR]: Invalid QT version - See above errors"
	kill -s TERM $$
    elif [[ -z "${PS_VERSION_3NUMBERS}" ]]
    then
	echo "[ERROR]: Invalid PySide/Shiboken version - See above errors"
	kill -s TERM $$
    elif [[ -z "${CN_VERSION_3NUMBERS}" ]]
    then
	echo "[ERROR]: Invalid Coin3D version - See above errors"
	kill -s TERM $$
    elif [[ -z "${FC_VERSION_3NUMBERS}" ]]
    then
	echo "[ERROR]: Invalid FreeCAD version - See above errors"
	kill -s TERM $$
    elif [[ -z "${QT_FORCE_RECOMPILE}" || ("${QT_FORCE_RECOMPILE}" != "0" && "${QT_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid QT recompile argument - See above errors"
	kill -s TERM $$
    elif [[ -z "${PS_FORCE_RECOMPILE}" || ("${PS_FORCE_RECOMPILE}" != "0" && "${PS_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid PySide/Shiboken recompile argument - See above errors"
	kill -s TERM $$
    elif [[ -z "${CN_FORCE_RECOMPILE}" || ("${CN_FORCE_RECOMPILE}" != "0" && "${CN_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid Coind3D recompile argument - See above errors"
	kill -s TERM $$
    elif [[ -z "${FC_FORCE_RECOMPILE}" || ("${FC_FORCE_RECOMPILE}" != "0" && "${FC_FORCE_RECOMPILE}" != "1") ]]
    then
	echo "[ERROR]: Invalid FreeCAD recompile argument - See above errors"
	kill -s TERM $$
    else
	mkdir -p "${CACHE_PATH}"	
    fi
}

gitPullMyOwnRepo()
{
    mkdir -p "${CACHE_PATH}"
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
		echo "[INFO ]: We just updated this script - We are going to restart it with the same arguments as you provided."
		exec ./CompileFreeCADQt3rdPartiesInDebug.sh "${SCRIPT_ARG1}" "${SCRIPT_ARG2}" "${SCRIPT_ARG3}" "${SCRIPT_ARG4}" "${SCRIPT_ARG5}" "${SCRIPT_ARG6}" "${SCRIPT_ARG7}" "${SCRIPT_ARG8}" "${SCRIPT_ARG9}"
	    fi
	fi
    fi
}

determinePlatform()
{
    PLATFORM_NAME="$(grep '^NAME=' /etc/os-release | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]' | cut -c 6-)"
    PLATFORM_VERSION="$(grep '^VERSION_ID=' /etc/os-release | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]' | cut -c 12-)"
    if [[ -z "${PLATFORM_VERSION}" ]]
    then
	PLATFORM_VERSION="$(grep '^IMAGE_VERSION=' /etc/os-release | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]' | cut -c 15-)"
    fi
}

setPackagesToInstall()
{
    if [[ "${PLATFORM_NAME}" == "ubuntu" && "${PLATFORM_VERSION}" =~ 24.* ]]
    then
	PACKAGE_MANAGER_COMMAND_UPDATE="apt-get update"
	PACKAGE_MANAGER_COMMAND_UPGRADE="apt-get upgrade"
	PACKAGE_MANAGER_COMMAND_INSTALL="apt-get install -y"
	PACKAGES_LIST=( "build-essential" "cmake" "valgrind" "python3" "ninja-build" "git" "perl")
    elif [[ "${PLATFORM_NAME}" == "arch linux" ]]
    then
	PACKAGE_MANAGER_COMMAND_UPDATE="pacman -y"
	PACKAGE_MANAGER_COMMAND_UPGRADE="pacman -Syu --noconfirm"
	PACKAGE_MANAGER_COMMAND_INSTALL="pacman -S --noconfirm"
	PACKAGES_LIST=( "gcc" "cmake" "valgrind" "python" "ninja" "git" "perl")
    else
	PACKAGE_MANAGER_COMMAND_UPDATE=""
	PACKAGE_MANAGER_COMMAND_UPGRADE=""
	PACKAGE_MANAGER_COMMAND_INSTALL=""
	PACKAGES_LIST=()
	echo "[ERROR]: Your platform is not managed by this script - Your platform: [${PLATFORM_NAME}] and version [${PLATFORM_VERSION}]"
	echo "[ERROR]: If you wish, you can request its implementation by:"
	echo "[ERROR]: creating an issue on GIT: https://github.com/huguesdpdn-aerospace/CompileFreeCADQt3rdPartiesInDebug/issues"
	echo "[ERROR]:     on the FreeCAD forum: https://forum.freecad.org/viewforum.php?f=4&sid=492b04c6ea9185bc2a97f3115ce31dac by tagging @huguesdpdn-aerospace"
	kill -s TERM $$
    fi
}

updateUpgradePackages()
{
    if [ -f "${CACHE_PATH}/UPDATE_UPGRADE_OK" ]
    then
	find "${CACHE_PATH}" -type f -name UPDATE_UPGRADE_OK -mtime +60 -delete
    fi
    if [ ! -f "${CACHE_PATH}/UPDATE_UPGRADE_OK" ]
    then
	if [ $(id -u) -ne 0 ]
	then
	    sudo ${PACKAGE_MANAGER_COMMAND_UPDATE}
	    update_return_code=$?
	    sudo ${PACKAGE_MANAGER_COMMAND_UPGRADE}
	    upgrade_return_code=$?
	else
	    ${PACKAGE_MANAGER_COMMAND_UPDATE}
	    update_return_code=$?
	    ${PACKAGE_MANAGER_COMMAND_UPGRADE}
	    upgrade_return_code=$?
	fi
	if [[ ${update_return_code} -eq 0 && ${upgrade_return_code} -eq 0 ]]
	then
	    touch "${CACHE_PATH}/UPDATE_UPGRADE_OK"
	fi
    fi
}

installPackages()
{
    if [ -f "${CACHE_PATH}/INSTALL_OK" ]
    then
	find "${CACHE_PATH}" -type f -name INSTALL_OK -mtime +180 -delete
    fi
    if [ ! -f "${CACHE_PATH}/INSTALL_OK" -a -n "${PACKAGE_MANAGER_COMMAND_INSTALL}" ]
    then
	packages_list_to_install=()
	for package_to_install in ${PACKAGES_LIST[@]}
	do
	    packages_list_to_install+=("${package_to_install}")
	    if [[ ${#packages_list_to_install[@]} -ge ${PACKAGES_INSTALL_PER} ]]
	    then
		if [ $(id -u) -ne 0 ]
		then
		    sudo ${PACKAGE_MANAGER_COMMAND_INSTALL} ${packages_list_to_install[@]}
		    install_return_code=$?
		else
		    ${PACKAGE_MANAGER_COMMAND_INSTALL} ${packages_list_to_install[@]}
		    install_return_code=$?
		fi
		if [[ ${install_return_code} -ne 0 ]]
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

QTSelectDesiredVersion()
{
    tags_list_available_in_git_repo=( $(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags https://code.qt.io/qt/qt5.git '*.*.*' | cut -d '/' -f 3 | tr -d ' ' | tr '[:upper:]' '[:lower:]' | sed 's/^v//g' | uniq | tr '\n' ' ') )
    if [[ "${QT_VERSION_3NUMBERS}" == "first-stable" ]]
    then
	version_found_index=0
    elif [[ "${QT_VERSION_3NUMBERS}" == "last-stable" ]]
    then
	version_found_index=${#tags_list_available_in_git_repo[@]}
	((version_found_index=version_found_index-1))
    elif [[ "${QT_VERSION_3NUMBERS}" == "current" || "${QT_VERSION_3NUMBERS}" == "pull" ]]
    then
	version_found_index=-1
	QT_VERSION_3NUMBERS="@"
    else
	version_found_index=-1
	for tag_available_in_git_repo_index in ${!tags_list_available_in_git_repo[@]}
	do
	    if [[ "${tags_list_available_in_git_repo[${tag_available_in_git_repo_index}]}" == "${QT_VERSION_3NUMBERS}" ]]
	    then
		version_found_index=${tag_available_in_git_repo_index}
		break
	    fi
	done
    fi
    if [[ "${QT_VERSION_3NUMBERS}" == "@" ]]
    then
	QT_VERSION_OFFSET=0
    elif [[ ${QT_VERSION_OFFSET} -eq 0 ]]
    then
	QT_VERSION_3NUMBERS="${tags_list_available_in_git_repo[version_found_index]}"
	QT_VERSION_OFFSET=0
    else
	new_version_after_offset=0
	((new_version_after_offset=version_found_index+QT_VERSION_OFFSET))
	if [[ ${new_version_after_offset} -lt 0 ]]
	then
	    echo "[ERROR]: The negative offset tag that your requested from tag '${QT_VERSION_3NUMBERS}' is too low - No so old tag found - Aborting"
	    kill -s TERM $$
	elif [[ ${new_version_after_offset} -ge ${#tags_list_available_in_git_repo[@]} ]]
	then
	    echo "[ERROR]: The positive offset tag that your requested from tag '${QT_VERSION_3NUMBERS}' is too high - No so recent tag found - Aborting"
	    kill -s TERM $$
	else
	    QT_VERSION_3NUMBERS="${tags_list_available_in_git_repo[${new_version_after_offset}]}"
	    QT_VERSION_OFFSET=0
	fi
    fi
}

QTDownload()
{
    cd "${INSTALL_PATH}"
    QT_PATH="${INSTALL_PATH}/QT_${QT_VERSION_3NUMBERS}"
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
	if [[ "${QT_VERSION_3NUMBERS}" == "current" || "${QT_VERSION_3NUMBERS}" == "pull" ]]
	then
	    if [[ "${QT_VERSION_3NUMBERS}" == "pull" ]]
	    then
		if ! git pull
		then
		    echo "[ERROR]: Fail to git pull QT repository"
		    kill -s TERM $$
		fi
	    fi
	elif [[ -n "${QT_CURRENT_TAG}" && "${QT_CURRENT_TAG}" != "v${QT_VERSION_3NUMBERS}" ]]
	then
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

QTConfigure()
{
    QT_PATH="${INSTALL_PATH}/QT_${QT_VERSION_3NUMBERS}"
    cd "${QT_PATH}"
    mkdir -p "build"
    mkdir -p "install"
    cd "build"
    
    ../configure -- "-DCMAKE_BUILD_TYPE=Debug" "-DFEATURE_developer_build=ON" "-DCMAKE_INSTALL_PREFIX=${QT_PATH}/install"
    cmake -- "-DCMAKE_BUILD_TYPE=Debug" "-DFEATURE_developer_build=ON" "-DCMAKE_INSTALL_PREFIX=${QT_PATH}/install"
}

QTBuild()
{
    echo "To implement..."
}

parseSingleArgument "${SCRIPT_ARG1}"
parseSingleArgument "${SCRIPT_ARG2}"
parseSingleArgument "${SCRIPT_ARG3}"
parseSingleArgument "${SCRIPT_ARG4}"
parseSingleArgument "${SCRIPT_ARG5}"
parseSingleArgument "${SCRIPT_ARG6}"
parseSingleArgument "${SCRIPT_ARG7}"
parseSingleArgument "${SCRIPT_ARG8}"
parseSingleArgument "${SCRIPT_ARG9}"
gitPullMyOwnRepo
determinePlatform
checkInstallPath
checkArguments
setPackagesToInstall
updateUpgradePackages
installPackages
QTSelectDesiredVersion
QTDownload
QTConfigure
QTBuild

#TODO
#Add disk space checker

