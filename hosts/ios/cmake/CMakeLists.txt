cmake_minimum_required ( VERSION 2.8.8 )
project ( moaiios )

if (${IOS_PLATFORM} STREQUAL "SIMULATOR")
set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphonesimulator")
else (${IOS_PLATFORM} STREQUAL "SIMULATOR")
set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos")
set (CMAKE_OSX_ARCHITECTURES "armv7" CACHE string  "Build architecture for iOS" )

endif (${IOS_PLATFORM} STREQUAL "SIMULATOR")

   FOREACH(DISABLED ${DISABLED_EXT} )
     set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDISABLE_${DISABLED}" CACHE INTERNAL "doc string" )
     set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DDISABLE_${DISABLED}" CACHE INTERNAL "doc string" )
     set ( DISABLE_${DISABLED} TRUE )
   ENDFOREACH()

#set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -DNDEBUG " CACHE INTERNAL "doc string")
#set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -DNDEBUG " CACHE INTERNAL "doc string")


add_subdirectory( ${LIBMOAI_DIR} ${CMAKE_CURRENT_BINARY_DIR}/libmoai )

add_subdirectory( "${BUILD_DIR}/resources" ${CMAKE_CURRENT_BINARY_DIR}/resources )

set ( INCLUDES_MOAIIOS
  "${SDK_DIR}/src/"
  "${SDK_DIR}/src/config-default/"
  "${SDK_DIR}/3rdparty/lua-5.1.3/src"
  "${SDK_DIR}/3rdparty/expat-2.0.1/lib"
  "${SDK_DIR}/3rdparty/tinyxml"
  "${SDK_DIR}/3rdparty"
  "${SDK_DIR}/3rdparty/freetype-2.4.4/include"
  "${SDK_DIR}/src/host-glut"
    CACHE INTERNAL "doc string" )

set ( IOS_HOST "${SDK_DIR}/xcode/ios")

include_directories (
    ${INCLUDES_MOAIIOS}
)


set ( MOAIIOS_SOURCES
     ${IOS_HOST}/main.mm
     ${IOS_HOST}/Classes/OpenGLView.mm
     ${IOS_HOST}/Classes/MoaiView.mm
     ${IOS_HOST}/Classes/MoaiVC.mm
     ${IOS_HOST}/Classes/MoaiAppDelegate.mm
     ${IOS_HOST}/Classes/LocationObserver.mm
     ${SDK_DIR}/src/host-glut/ParticlePresets.cpp
)

set ( MOAIIOS_RESOURCES
     ${IOS_HOST}/Icon-72.png
     ${IOS_HOST}/Icon-Small-50.png
     ${IOS_HOST}/Icon-Small.png
     ${IOS_HOST}/Icon-Small@2x.png
     ${IOS_HOST}/Icon.png
     ${IOS_HOST}/Icon@2x.png


)


  SET_SOURCE_FILES_PROPERTIES(
    ${MOAIIOS_RESOURCES}
    PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources
    )


  SET_SOURCE_FILES_PROPERTIES(
    ${PROJECT_RESOURCES}
    PROPERTIES
    MACOSX_PACKAGE_LOCATION moai.app/lua
  )



     
add_executable ( moai MACOSX_BUNDLE ${MOAIIOS_SOURCES} ${MOAIIOS_RESOURCES} ${PROJECT_RESOURCES})


target_link_libraries ( moai
   moai-sim
   moai-luaext
   moai-chipmunk
   moai-untz
   moai-http-client
   moai-util
   moai-iphone
   moai-audiosampler
   moai-core
   zlcore
   third-party
   plugins
)



if ( MOAI_BOX2D )
  target_link_libraries ( moai moai-box2d )
endif ( MOAI_BOX2D )

#frameworks
macro(ADD_FRAMEWORK fwname appname)
    find_library(FRAMEWORK_${fwname}
        NAMES ${fwname}
        PATHS ${CMAKE_SYSTEM_FRAMEWORK_PATH}
        NO_DEFAULT_PATH)
    if( ${FRAMEWORK_${fwname}} STREQUAL FRAMEWORK_${fwname}-NOTFOUND)
        MESSAGE(ERROR ": Framework ${fwname} not found")
    else()
        TARGET_LINK_LIBRARIES(${appname} "${FRAMEWORK_${fwname}}/${fwname}")
        MESSAGE(STATUS "Framework ${fwname} found at ${FRAMEWORK_${fwname}}")
    endif()
endmacro(ADD_FRAMEWORK)

macro(ADD_FRAMEWORKS appname fwnames)
  FOREACH(FW ${fwnames})
    ADD_FRAMEWORK(${FW} ${appname})
  ENDFOREACH(FW)
endmacro(ADD_FRAMEWORKS)

set( FWORKS
                  AdSupport
                  AudioToolbox
                  CoreAudio
                  CoreGraphics
                  CoreLocation
                  CoreTelephony
                  CFNetwork
                  Foundation
                  GameKit
                  MediaPlayer
                  MessageUI
                  OpenGLES
                  QuartzCore
                  StoreKit
                  SystemConfiguration
                  Twitter
                  UIKit)

ADD_FRAMEWORKS(moai "${FWORKS}")






set_target_properties(moai PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${SIGN_IDENTITY}")
set_target_properties(moai PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_LIST_DIR}/moai-Info.plist)

 
