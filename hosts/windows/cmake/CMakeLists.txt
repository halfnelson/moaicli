cmake_minimum_required ( VERSION 2.8.8 )
project ( moaihost )




add_subdirectory( ${LIBMOAI_DIR} ${CMAKE_CURRENT_BINARY_DIR}/libmoai )

 find_package ( OpenGL REQUIRED )

 set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DFREEGLUT_STATIC -static -Os " CACHE INTERNAL "doc string")
set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DFREEGLUT_STATIC -static -Os " CACHE INTERNAL "doc string")

 set ( INCLUDES_MOAIHOSTGLUT 
  "${SDK_DIR}/src/"
  "${SDK_DIR}/src/config-default/"
  "${SDK_DIR}/src/host-glut/"
  "${SDK_DIR}/3rdparty/lua-5.1.3/src"
  "${SDK_DIR}/3rdparty/alcfreeglut/install/usr/include/GL"
  "${SDK_DIR}/3rdparty/alcfreeglut/install/usr/include"
  
  ${OPENGL_INCLUDE_DIRS}
  
  CACHE INTERNAL "doc string" )

  include_directories ( ${INCLUDES_MOAIHOSTGLUT} )

 


# freeglut mingw
file ( GLOB FREEGLUT_SRC "${SDK_DIR}/3rdparty/alcfreeglut/src/*.c" )
add_library( freeglut_static STATIC ${FREEGLUT_SRC})

 set ( CMAKE_CURRENT_SOURCE_DIR "${SDK_DIR}/src/host-glut" )

 add_executable ( moai
  ${CMAKE_CURRENT_SOURCE_DIR}/GlutHost.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/GlutHostMain.cpp
)


message ("opengl ${OPENGL_LIBRARIES}")
target_link_libraries ( moai 
  moai-sim
  moai-luaext
  moai-util
  moai-core
  zlcore
  plugins
  freeglut_static
  ${OPENGL_LIBRARIES}
  third-party
)

if (MOAI_HTTP_CLIENT)
  target_link_libraries ( moai moai-http-client)
endif (MOAI_HTTP_CLIENT)

if ( MOAI_UNTZ )
   target_link_libraries ( moai moai-untz )
endif ( MOAI_UNTZ )

if ( MOAI_BOX2D )
  target_link_libraries ( moai moai-box2d )
endif ( MOAI_BOX2D )

 if (BUILD_WINDOWS)   
  target_link_libraries ( moai winmm  )
 endif (BUILD_WINDOWS)
 