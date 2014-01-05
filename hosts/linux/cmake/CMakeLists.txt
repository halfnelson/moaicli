cmake_minimum_required ( VERSION 2.8.8 )
project ( moaiglut )

message ( "${CMAKE_C_FLAGS}" )
set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DNDEBUG " CACHE INTERNAL "doc string")
set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNDEBUG" CACHE INTERNAL "doc string")


add_subdirectory( ${LIBMOAI_DIR} ${CMAKE_CURRENT_BINARY_DIR}/libmoai )


