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

# Translations: kcm_glassfort_timemachine-<lang>.po -> <lang>/LC_MESSAGES
# (the QML engine of a KCM uses the plugin id as its i18n domain).
find_program(MSGFMT msgfmt REQUIRED)
file(GLOB _po_files CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/kcm_glassfort_timemachine-*.po")
foreach(_po ${_po_files})
    get_filename_component(_name "${_po}" NAME_WE)
    string(REPLACE "kcm_glassfort_timemachine-" "" _lang "${_name}")
    set(_mo "${CMAKE_CURRENT_BINARY_DIR}/${_lang}/kcm_glassfort_timemachine.mo")
    add_custom_command(OUTPUT "${_mo}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${_lang}"
        COMMAND ${MSGFMT} --check -o "${_mo}" "${_po}"
        DEPENDS "${_po}")
    list(APPEND _mo_files "${_mo}")
    install(FILES "${_mo}" DESTINATION "${KDE_INSTALL_LOCALEDIR}/${_lang}/LC_MESSAGES")
endforeach()
add_custom_target(translations ALL DEPENDS ${_mo_files})
