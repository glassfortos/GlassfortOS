# SPDX-License-Identifier: GPL-3.0-or-later
cmake_minimum_required(VERSION 3.20)
project(glassfort-timemachine VERSION 0.1.0 LANGUAGES CXX)

set(QT_MIN_VERSION "6.8.0")
set(KF_MIN_VERSION "6.10.0")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core DBus Qml Quick Test)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS CoreAddons I18n KCMUtils)

add_definitions(-DTRANSLATION_DOMAIN=\"kcm_glassfort_timemachine\")

# Like kcmutils_add_qml_kcm, but with a flat source folder (makepkg takes
# local sources from the PKGBUILD folder only, the macro wants ui/).
kcoreaddons_add_plugin(kcm_glassfort_timemachine
    INSTALL_NAMESPACE plasma/kcms/systemsettings
    SOURCES restorepoints.cpp snapshotmodel.cpp)
kcmutils_generate_desktop_file(kcm_glassfort_timemachine)
qt_add_resources(kcm_glassfort_timemachine "ui"
    PREFIX "/kcm/kcm_glassfort_timemachine"
    FILES main.qml)
target_link_libraries(kcm_glassfort_timemachine PRIVATE
    Qt6::DBus Qt6::Quick KF6::CoreAddons KF6::I18n KF6::KCMUtilsQuick)

# Unit tests for the parts without D-Bus.
enable_testing()
add_executable(snapshotmodeltest snapshotmodeltest.cpp snapshotmodel.cpp)
target_link_libraries(snapshotmodeltest PRIVATE Qt6::DBus Qt6::Test KF6::I18n)
add_test(NAME snapshotmodeltest COMMAND snapshotmodeltest)
