FUNCTION(QUERY_QMAKE VAR RESULT)
    GET_TARGET_PROPERTY(QMAKE_EXECUTABLE Qt5::qmake LOCATION)
    EXEC_PROGRAM(${QMAKE_EXECUTABLE} ARGS "-query ${VAR}" RETURN_VALUE return_code OUTPUT_VARIABLE output )
    IF(NOT return_code)
        FILE(TO_CMAKE_PATH "${output}" output)
        SET(${RESULT} ${output} PARENT_SCOPE)
    ENDIF(NOT return_code)
ENDFUNCTION(QUERY_QMAKE)

FUNCTION(FIND_LIB PATH_WHERE_SEARCH _NAME RESULT)
    STRING(REGEX REPLACE "[(0-9)]+$" "" CLEARNAME ${_NAME})
    STRING(REGEX REPLACE ${CLEARNAME} "" VERSION ${_NAME}) 
    SET(name_stable "${CMAKE_SHARED_LIBRARY_PREFIX}${_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    SET(PLUGIN "${PATH_WHERE_SEARCH}/${name_stable}")
    #trying to search lib with suffix 5
    IF(NOT EXISTS ${PLUGIN})
        SET(PLUGIN "${PATH_WHERE_SEARCH}/${CMAKE_SHARED_LIBRARY_PREFIX}${CLEARNAME}${CMAKE_SHARED_LIBRARY_SUFFIX}.${VERSION}")
    ENDIF()
    IF(EXISTS ${PLUGIN})
        SET(${RESULT} ${PLUGIN} PARENT_SCOPE)
    ENDIF()  
ENDFUNCTION(FIND_LIB)

MACRO(DEPLOY_QT_PLUGIN_HELPER _path PATH_WHERE_SEARCH LIB_DIST TYPE)
    GET_FILENAME_COMPONENT(dir ${_path} PATH)
    GET_FILENAME_COMPONENT(name ${_path} NAME_WE)
    STRING(TOUPPER ${TYPE} _type) 
    IF(${_type} STREQUAL "DEBUG")# try to find debug version of library 
        SET(name_local "${name}${CMAKE_DEBUG_POSTFIX}")
        FIND_LIB(${PATH_WHERE_SEARCH}/${dir} ${name_local} PLUGIN_${TYPE}_${name})  
    ENDIF()
    IF(NOT PLUGIN_${TYPE}_${name})
        FIND_LIB(${PATH_WHERE_SEARCH}/${dir} ${name} PLUGIN_${TYPE}_${name}) 
    ENDIF()

    IF(PLUGIN_${TYPE}_${name})
        GET_FILENAME_COMPONENT(LibWithoutSymLink ${PLUGIN_${TYPE}_${name}} REALPATH)
        GET_FILENAME_COMPONENT(PLUGIN_NAME ${PLUGIN_${TYPE}_${name}} NAME)
        IF(NOT ${PLUGIN_${TYPE}_${name}} STREQUAL ${LibWithoutSymLink})
            MESSAGE(STATUS "Deployng ${PLUGIN} plugin for ${TYPE}, realpath is ${LibWithoutSymLink}, name ${PLUGIN_NAME}")
            INSTALL(FILES ${LibWithoutSymLink} DESTINATION "${LIB_DIST}/${dir}" CONFIGURATIONS ${TYPE} COMPONENT Runtime RENAME ${PLUGIN_NAME})
        ELSE()
            MESSAGE(STATUS "Deployng ${PLUGIN_${TYPE}_${name}} plugin for ${TYPE}")
            INSTALL(FILES ${PLUGIN_${TYPE}_${name}} DESTINATION "${LIB_DIST}/${dir}" CONFIGURATIONS ${TYPE} COMPONENT Runtime)
        ENDIF()
        #SET(LIBS_TO_FIXUP ${LIB_DIST}/${dir} ${LIBS_TO_FIXUP})
        #STRING(REPLACE "${QT_IMAGEFORMATS_PLUGINS_DIR}" "${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}.app/Contents/MacOS/imageformats" 
        #    QT_IMAGEFORMATS_PLUGIN_LOCAL ${QT_${PLUGIN}_PLUGIN_DEBUG}
        #    )
        #LIST(APPEND BUNDLE_LIBRARIES_MOVE ${QT_IMAGEFORMATS_PLUGIN_LOCAL})
    ELSE()
        MESSAGE(STATUS "Could not deploy ${PLUGIN_${name}}, required path: ${_path}, plugin for ${TYPE}")
    ENDIF()
ENDMACRO(DEPLOY_QT_PLUGIN_HELPER)

MACRO(DEPLOY_QT_PLUGIN _path PATH_WHERE_SEARCH LIB_DIST)
    IF(NOT CMAKE_BUILD_TYPE AND CMAKE_CONFIGURATION_TYPES)
        FOREACH(buildconfig ${CMAKE_CONFIGURATION_TYPES})
            DEPLOY_QT_PLUGIN_HELPER(${_path} ${PATH_WHERE_SEARCH} ${LIB_DIST} ${buildconfig})
        ENDFOREACH(buildconfig ${CMAKE_CONFIGURATION_TYPES})
    ELSEIF(CMAKE_BUILD_TYPE)
        DEPLOY_QT_PLUGIN_HELPER(${_path} ${PATH_WHERE_SEARCH} ${LIB_DIST} ${CMAKE_BUILD_TYPE})
    ENDIF(NOT CMAKE_BUILD_TYPE AND CMAKE_CONFIGURATION_TYPES)
ENDMACRO(DEPLOY_QT_PLUGIN)

MACRO(DETECT_QT)
    FIND_PACKAGE( Qt5Core QUIET )
    IF(Qt5Core_FOUND)
            SET(DEVELOPER_QT5 1)
    ELSE(Qt5Core_FOUND)
            SET(DEVELOPER_QT5 0)
    ENDIF(Qt5Core_FOUND)
ENDMACRO(DETECT_QT)

MACRO(QTX_WRAP_CPP)
    IF(DEVELOPER_QT5)
        QT5_WRAP_CPP(${ARGN})
    ELSE(DEVELOPER_QT5)
        QT4_WRAP_CPP(${ARGN})
    ENDIF(DEVELOPER_QT5)
ENDMACRO(QTX_WRAP_CPP)

MACRO(QTX_GENERATE_MOC)
    IF(DEVELOPER_QT5)
        QT5_GENERATE_MOC(${ARGN})
    ELSE(DEVELOPER_QT5)
        QT4_GENERATE_MOC(${ARGN})
    ENDIF(DEVELOPER_QT5)
ENDMACRO(QTX_GENERATE_MOC)

MACRO(QTX_ADD_TRANSLATION)
    IF(DEVELOPER_QT5)
        QT5_ADD_TRANSLATION(${ARGN})
    ELSE(DEVELOPER_QT5)
        QT4_ADD_TRANSLATION(${ARGN})
    ENDIF(DEVELOPER_QT5)
ENDMACRO(QTX_ADD_TRANSLATION)

MACRO(QTX_CREATE_TRANSLATION)
    IF(DEVELOPER_QT5)
        QT5_CREATE_TRANSLATION(${ARGN})
    ELSE(DEVELOPER_QT5)
        QT4_CREATE_TRANSLATION(${ARGN})
    ENDIF(DEVELOPER_QT5)
ENDMACRO(QTX_CREATE_TRANSLATION)

MACRO(QTX_WRAP_UI)
    IF(DEVELOPER_QT5)
        QT5_WRAP_UI(${ARGN})
    ELSE(DEVELOPER_QT5)
        QT4_WRAP_UI(${ARGN})
    ENDIF(DEVELOPER_QT5)
ENDMACRO(QTX_WRAP_UI)

MACRO(QTX_ADD_RESOURCES)
    IF(DEVELOPER_QT5)
        QT5_ADD_RESOURCES(${ARGN})
    ELSE(DEVELOPER_QT5)
        QT4_ADD_RESOURCES(${ARGN})
    ENDIF(DEVELOPER_QT5)
ENDMACRO(QTX_ADD_RESOURCES)

MACRO(INTEGRATE_QT)
QUERY_QMAKE(QT_INSTALL_PLUGINS QT_PLUGINS_DIR)
QUERY_QMAKE(QT_INSTALL_BINS QT_BINS_DIR)
QUERY_QMAKE(QT_INSTALL_LIBS QT_LIBS_DIR)
IF(DEVELOPER_QT5)
    SET(USE_QT_DYNAMIC ON)
    SET(QT_COMPONENTS_TO_USE ${ARGV})

    IF(DEVELOPER_BUILD_TESTS)
        SET(QT_COMPONENTS_TO_USE ${QT_COMPONENTS_TO_USE} Qt5Test)
    ENDIF(DEVELOPER_BUILD_TESTS)

    FOREACH(qtComponent ${QT_COMPONENTS_TO_USE})
        IF(NOT ${qtComponent} STREQUAL "Qt5ScriptTools")
            FIND_PACKAGE(${qtComponent} REQUIRED)
        ELSE()
            FIND_PACKAGE(${qtComponent} QUIET)
        ENDIF()
    
        INCLUDE_DIRECTORIES( ${${qtComponent}_INCLUDE_DIRS} )
        #STRING(REGEX REPLACE "Qt5" "" COMPONENT_SHORT_NAME ${qtComponent})		
        #set(QT_MODULES_TO_USE ${QT_MODULES_TO_USE} ${COMPONENT_SHORT_NAME})
        IF(${${qtComponent}_FOUND} AND NOT(${qtComponent} STREQUAL "Qt5LinguistTools"))
        STRING(REGEX REPLACE "Qt5" "" componentShortName ${qtComponent})		
                    SET(QT_LIBRARIES ${QT_LIBRARIES} "Qt5::${componentShortName}")
        ENDIF()
    ENDFOREACH(qtComponent ${QT_COMPONENTS_TO_USE})
    
    IF(NOT Qt5ScriptTools_FOUND)
        ADD_DEFINITIONS(-DQT_NO_SCRIPTTOOLS)
    ENDIF()

    IF(DEVELOPER_OPENGL)
        FIND_PACKAGE(Qt5OpenGL REQUIRED)
        INCLUDE_DIRECTORIES( ${Qt5OpenGL_INCLUDE_DIRS})
    ENDIF(DEVELOPER_OPENGL)
    SETUP_COMPILER_SETTINGS(${USE_QT_DYNAMIC})
ELSE(DEVELOPER_QT5)
    SET(QT_COMPONENTS_TO_USE ${ARGV})
    # repeat this for every debug/optional package
    LIST(FIND QT_COMPONENTS_TO_USE "QtScriptTools" QT_SCRIPT_TOOLS_INDEX)
    IF(NOT ${QT_SCRIPT_TOOLS_INDEX} EQUAL -1)
        LIST(REMOVE_ITEM QT_COMPONENTS_TO_USE "QtScriptTools")
        SET(QT_DEBUG_COMPONENTS_TO_USE ${QT_DEBUG_COMPONENTS_TO_USE} "QtScriptTools")
    ENDIF()
    IF(DEVELOPER_BUILD_TESTS)
        SET(QT_COMPONENTS_TO_USE ${QT_COMPONENTS_TO_USE} QtTest)
    ENDIF(DEVELOPER_BUILD_TESTS)
    FIND_PACKAGE(Qt4 COMPONENTS ${QT_COMPONENTS_TO_USE} REQUIRED)
    FIND_PACKAGE(Qt4 COMPONENTS ${QT_DEBUG_COMPONENTS_TO_USE} QUIET)
    IF(NOT QT_QTSCRIPTTOOLS_FOUND)
        ADD_DEFINITIONS(-DQT_NO_SCRIPTTOOLS)
    ENDIF()
    INCLUDE(${QT_USE_FILE})
    SET(QT_3RDPARTY_DIR ${QT_BINARY_DIR}/../src/3rdparty)

	#checking is Qt dynamic or statis version will be used
    GET_FILENAME_COMPONENT(QTCORE_DLL_NAME_WE ${QT_QTCORE_LIBRARY_RELEASE} NAME_WE)
    GET_FILENAME_COMPONENT(QT_LIB_PATH ${QT_QTCORE_LIBRARY_RELEASE} PATH)

    IF(WIN32)
        SET(DLL_EXT dll)
    # message("searching ${QTCORE_DLL_NAME_WE}.${DLL_EXT} in " ${QT_LIB_PATH} ${QT_LIB_PATH}/../bin)
        FIND_FILE(QTCORE_DLL_FOUND_PATH ${QTCORE_DLL_NAME_WE}.${DLL_EXT} PATHS ${QT_LIB_PATH} ${QT_LIB_PATH}/../bin
            NO_DEFAULT_PATH
            NO_CMAKE_ENVIRONMENT_PATH
            NO_CMAKE_PATH
            NO_SYSTEM_ENVIRONMENT_PATH
            NO_CMAKE_SYSTEM_PATH
            )
            MESSAGE("QTCORE_DLL_FOUND_PATH=" ${QTCORE_DLL_FOUND_PATH})
            IF(EXISTS ${QTCORE_DLL_FOUND_PATH})
                SET(USE_QT_DYNAMIC ON)
            ELSE(EXISTS ${QTCORE_DLL_FOUND_PATH})
                SET(USE_QT_DYNAMIC OFF)
            ENDIF(EXISTS ${QTCORE_DLL_FOUND_PATH})
    ELSE()
        SET(USE_QT_DYNAMIC ON)
    ENDIF(WIN32)
    SETUP_COMPILER_SETTINGS(${USE_QT_DYNAMIC})
    # use jscore
    IF(MSVC AND NOT USE_QT_DYNAMIC)
        FIND_LIBRARY(JSCORE_LIB_RELEASE jscore
            PATHS
            ${QT_3RDPARTY_DIR}/webkit/Source/JavaScriptCore/release
            ${QT_3RDPARTY_DIR}/webkit/JavaScriptCore/release
            )
        FIND_LIBRARY(JSCORE_LIB_DEBUG NAMES jscored jscore
            PATHS
            ${QT_3RDPARTY_DIR}/webkit/Source/JavaScriptCore/debug
            ${QT_3RDPARTY_DIR}/webkit/JavaScriptCore/debug
            )
    SET(JSCORE_LIBS optimized ${JSCORE_LIB_RELEASE} debug ${JSCORE_LIB_DEBUG} )
    ENDIF(MSVC AND NOT USE_QT_DYNAMIC)
	# end of use jscore
ENDIF(DEVELOPER_QT5)

ENDMACRO(INTEGRATE_QT)


##############################################################################

MACRO(INSTALL_QT TARGET_NAME LIB_DIST)
IF(NOT DEVELOPER_QT5)
    IF(WIN32 OR APPLE)
        SET(QT_COMPONENTS_TO_USE ${ARGV})
        LIST(REMOVE_ITEM QT_COMPONENTS_TO_USE ${TARGET_NAME})
        FIND_PACKAGE(Qt4 COMPONENTS ${QT_COMPONENTS_TO_USE} REQUIRED)
        FIND_PACKAGE(Qt4 COMPONENTS ${QT_DEBUG_COMPONENTS_TO_USE} QUIET)
        INCLUDE(${QT_USE_FILE})
        GET_TARGET_PROPERTY(targetLocation ${TARGET_NAME} LOCATION)
        GET_FILENAME_COMPONENT(targetDir ${targetLocation} PATH)
        
        IF(WIN32)
            SET(REPLACE_IN_LIB ".lib" ".dll")
            SET(REPLACE_IN_LIB2 "/lib/([^/]+)$" "/bin/\\1")
        ELSEIF(APPLE)
            SET(REPLACE_IN_LIB ".a" ".dylib")
            SET(REPLACE_IN_LIB2 "" "")
        ENDIF()

        FOREACH(qtComponent ${QT_COMPONENTS_TO_USE} ${QT_DEBUG_COMPONENTS_TO_USE})
            STRING(TOUPPER "${qtComponent}" QtComCap)
            TARGET_LINK_LIBRARIES(${TARGET_NAME} ${QT_${QtComCap}_LIBRARY})
            IF(NOT ${qtComponent} STREQUAL "QtMain")
                STRING(REPLACE ${REPLACE_IN_LIB} dllNameDeb "${QT_${QtComCap}_LIBRARY_DEBUG}")
                IF(WIN32)
                    STRING(REGEX REPLACE ${REPLACE_IN_LIB2} dllNameDeb ${dllNameDeb})
                ENDIF()
                SET(DLIBS_TO_COPY_DEBUG ${DLIBS_TO_COPY_DEBUG} ${dllNameDeb})
                IF(NOT ${qtComponent} STREQUAL "QtScriptTools")
                    STRING(REPLACE ${REPLACE_IN_LIB} dllNameRel "${QT_${QtComCap}_LIBRARY_RELEASE}")
                    IF(WIN32)
                        STRING(REGEX REPLACE ${REPLACE_IN_LIB2} dllNameRel ${dllNameRel})
                    ENDIF()
                    SET(DLIBS_TO_COPY_RELEASE ${DLIBS_TO_COPY_RELEASE} ${dllNameRel})
                ENDIF()
                # TODO: check this code @ MAC and *ux
                ADD_CUSTOM_COMMAND(TARGET ${TARGET_NAME} POST_BUILD COMMAND
                    ${CMAKE_COMMAND} -E copy $<$<CONFIG:Debug>:
                    ${dllNameDeb}> $<$<NOT:$<CONFIG:Debug>>:
                    ${dllNameRel}>  $<TARGET_FILE_DIR:${TARGET_NAME}>
                    )
            ENDIF(NOT ${qtComponent} STREQUAL "QtMain")
        ENDFOREACH(qtComponent ${QT_COMPONENTS_TO_USE})
    ENDIF(WIN32 OR APPLE)
ELSE()# Qt5
    LIST(FIND QT_COMPONENTS_TO_USE "Qt5Xml" QT_XML_INDEX)
    IF(NOT ${QT_XML_INDEX} EQUAL -1)
        GET_TARGET_PROPERTY(libLocation ${Qt5Xml_LIBRARIES} LOCATION)
        STRING(REGEX REPLACE "Xml" "XmlPatterns" libLocation ${libLocation})
        QT_ADD_TO_INSTALL(${TARGET_NAME} ${libLocation} "")
    ENDIF()
    FOREACH(qtComponent ${QT_COMPONENTS_TO_USE} ${QT_DEBUG_COMPONENTS_TO_USE})
        IF(NOT ${qtComponent} STREQUAL "Qt5LinguistTools")
            IF(NOT "${${qtComponent}_LIBRARIES}" STREQUAL "")
                GET_TARGET_PROPERTY(libLocation ${${qtComponent}_LIBRARIES} LOCATION)
                QT_ADD_TO_INSTALL(${TARGET_NAME} ${libLocation} "")
            ELSE(NOT "${${qtComponent}_LIBRARIES}" STREQUAL "")
                MESSAGE("Canont find library ${qtComponent}_LIBRARIES")
            ENDIF(NOT "${${qtComponent}_LIBRARIES}" STREQUAL "")
        ENDIF()
    ENDFOREACH(qtComponent ${QT_COMPONENTS_TO_USE} ${QT_DEBUG_COMPONENTS_TO_USE})
ENDIF(NOT DEVELOPER_QT5)

MESSAGE(STATUS "Qt libs to install ${DLIBS_TO_COPY_RELEASE}")
IF(MSVC OR APPLE)
    # Visual studio install
    FOREACH(buildconfig ${CMAKE_CONFIGURATION_TYPES})
        IF(${buildconfig} STREQUAL "Debug")
            SET(DLIBS_TO_COPY ${DLIBS_TO_COPY_ALL} ${DLIBS_TO_COPY_DEBUG})
        ELSE()
            SET(DLIBS_TO_COPY ${DLIBS_TO_COPY_ALL} ${DLIBS_TO_COPY_RELEASE})
        ENDIF()
        INSTALL(FILES ${DLIBS_TO_COPY} DESTINATION ${LIB_DIST} CONFIGURATIONS ${buildconfig} )
    ENDFOREACH(buildconfig ${CMAKE_CONFIGURATION_TYPES})
ELSEIF(UNIX)
    # Make install
    STRING(TOUPPER ${CMAKE_BUILD_TYPE} TYPE)
    IF(${TYPE} STREQUAL "DEBUG")
        SET(DLIBS_TO_COPY ${DLIBS_TO_COPY_ALL} ${DLIBS_TO_COPY_DEBUG})
    ELSE()
        SET(DLIBS_TO_COPY ${DLIBS_TO_COPY_ALL} ${DLIBS_TO_COPY_RELEASE})
    ENDIF()
    IF(WIN32 OR APPLE)
        INSTALL(FILES ${DLIBS_TO_COPY} DESTINATION ${LIB_DIST})	
    ELSE()
    #eliminate symlinks
        FOREACH(dllsToCopy ${DLIBS_TO_COPY})		
            GET_FILENAME_COMPONENT(name ${dllsToCopy} NAME)
            STRING(REGEX REPLACE "[^5]+$" "" lnname ${name})
            INSTALL(FILES ${dllsToCopy} DESTINATION ${LIB_DIST} CONFIGURATIONS ${TYPE} COMPONENT Runtime RENAME ${lnname})    
        ENDFOREACH(dllsToCopy ${DLIBS_TO_COPY})
    ENDIF()
ENDIF(MSVC OR APPLE)
		
ENDMACRO(INSTALL_QT)

MACRO(QT_ADD_TO_INSTALL TARGET_NAME libLocation copyToSubdirectory)
    SET(libLocation_release ${libLocation})
    SET(REPLACE_PATTERN "/lib/([^/]+)$" "/bin/\\1") # from lib to bin
    IF(NOT EXISTS "${libLocation_release}")
        STRING(REGEX REPLACE ${REPLACE_PATTERN} libLocation_release ${libLocation_release})
    ENDIF()
    IF(EXISTS "${libLocation_release}")
        SET(DLIBS_TO_COPY_RELEASE ${DLIBS_TO_COPY_RELEASE} ${libLocation_release})
        STRING(REGEX REPLACE ${CMAKE_SHARED_LIBRARY_SUFFIX} ${CMAKE_DEBUG_POSTFIX}${CMAKE_SHARED_LIBRARY_SUFFIX} libLocation_debug ${libLocation_release})
        IF(EXISTS "${libLocation_debug}")
            SET(DLIBS_TO_COPY_DEBUG ${DLIBS_TO_COPY_DEBUG} ${libLocation_debug})
        ELSE()
            SET(DLIBS_TO_COPY_DEBUG ${DLIBS_TO_COPY_DEBUG} ${libLocation_release})
        ENDIF()
    ENDIF()
ENDMACRO(QT_ADD_TO_INSTALL)