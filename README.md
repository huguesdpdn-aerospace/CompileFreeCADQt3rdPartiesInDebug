# Compile FreeCAD , QT , PySide , Shiboken , Coin3D in debug mode by yourself on Linux





## Overview

This tool is intended for people or developers that wish to:

- check that compilation is working under Linux
- check that compilation do not throw any warning
- debug FreeCAD with `valgrind` 
- debug any 3rd parties software by using the `valgrind` tool
- try and check some custom code





## Libraries recompiled with debug symbols

The goal is to compile in debug mode libraries used by FreeCAD

- FreeCAD
- QT
- PySide
- Shiboken
- Coin3D

NOTICE : The goal is to only compile the N-1 libraries used by FreeCAD.  We will not compile libraries at N-2 or lower levels since, if there is an issue in one of them, it should be reproduce with the incriminated library in a standalone mode, not with FreeCAD. We are NOT going to build/compile XCB library, OpenGL, etc.





## Currently supported OS:

- Ubuntu and derivate (Kubuntu / Xubuntu / Lubuntu / Ubuntu MATE / Ubuntu Budgie / Ubuntu Kylin / Ubuntu Studio)

That's all for the moment. If you wish to add your operating system, feel free to provide a pull-request





## Install and launch the full debug install:

```bash
git clone https://github.com/huguesdpdn-aerospace/CompileFreeCADQt3rdPartiesInDebug.git CompileFreeCADQt3rdPartiesInDebug

cd CompileFreeCADQt3rdPartiesInDebug

./CompileFreeCADQt3rdPartiesInDebug.sh
```

NOTICE : Your `root` or `sudo` password will be asked either:

- once (if you already run this script at least once)
- several times (for the first time) at the beginning in order to install all necessary packages and missing dependencies





## Options

You can request the following options to the `CompileFreeCADQt3rdPartiesInDebug.sh` script:

| Argument              | Default value         | Description                                                  | Examples                                    |
| --------------------- | --------------------- | ------------------------------------------------------------ | ------------------------------------------- |
| --install-path        | ${HOME}/FreeCADDebug/ | Will install all debug compiled libraries under this path    | --install-path=/tmp                         |
| --qt-version=X.X.X    | last                  | Download, compile and install the specified QT version (if not already done) | --qt-version=last<br />--qt-version=6.5.2   |
| --qt-force-recompile  | (disabled)            | If specified and if the desired QT version has already been compiled previously, compilation files and binaries build will be deleted and compiled again. | --qt-force-recompile                        |
| --ps-version=X.X.X    | last                  | Download, compile and install the specified PySide/Shiboken version (if not already done) | --ps-version=last<br />--ps-version=6.3.1   |
| --ps-force-recompile  | (disabled)            | If specified and if the desired PySide/Shiboken version has already been compiled previously, compilation files and binaries build will be deleted and compiled again. | --ps-force-recompile                        |
| --c3d-version=X.X.X   | last                  | Download, compile and install the specificied Coin3D version (if not already done) | --c3d-version=last<br />--c3d-version=3.1.0 |
| --c3d-force-recompile | (disabled)            | If specified and if the desired Coin3D version has already been compiled previously, compilation files and binaries build will be deleted and compiled again. | --c3d-force-recompile                       |
| --fc-version=X.X.X    | last                  | Download, compile and install the specified FreeCAD version (if not already done) | --fc-version=last<br />--fc-version=0.21.2  |
| --fc-force-recompile  | (disabled)            | If specified and if the desired FreeCAD version has already been compiled previously, compilation files and binaries build will be deleted and compiled again. | --fc-force-recompile                        |





## An error? Want to contribute?

You can submit a pull-request at anytime, your contribution would be welcome.