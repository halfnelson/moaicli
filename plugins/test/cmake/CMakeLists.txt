cmake_minimum_required ( VERSION 2.8.5 )
project ( plugin-test )

  set ( MY_SOURCE_DIR "${PLUGIN_DIR}/test/src" )
  
  include_directories ( 
    ${THIRD_PARTY_INCLUDES}
  )

  add_library ( plugin-test OBJECT
      ${MY_SOURCE_DIR}/plugin.cpp
  )
