TARGET?=GO
SWIG = swig -DSWIGWORDSIZE64
CXX = g++
CLIENT_TYPE = GRIDDB_GO

ARCH = $(shell arch)

LDFLAGS = -Llibs -lpthread -lrt -lgridstore
CPPFLAGS = -fPIC -std=c++0x -g -O2 -D$(CLIENT_TYPE)
INCLUDES = -Iinclude -Isrc

INCLUDES_GO = $(INCLUDES)
CPPFLAGS_GO = $(CPPFLAGS) $(INCLUDES_GO) -I_obj

PROGRAM = griddb_go.so
EXTRA = griddb_go.go _cgo_export.o

SOURCES = 	  src/TimeSeriesProperties.cpp \
		  src/ContainerInfo.cpp			\
		  src/Field.cpp \
		  src/AggregationResult.cpp	\
		  src/Container.cpp			\
		  src/Store.cpp			\
		  src/StoreFactory.cpp	\
		  src/PartitionController.cpp	\
		  src/Query.cpp				\
		  src/QueryAnalysisEntry.cpp			\
		  src/RowKeyPredicate.cpp	\
		  src/RowSet.cpp			\
		  src/Util.cpp				\


all: $(PROGRAM)

SWIG_DEF = src/griddb.i

SWIG_GO_SOURCES     = src/griddb_go.cxx

OBJS = $(SOURCES:.cpp=.o)
SWIG_GO_OBJS = $(SWIG_GO_SOURCES:.cxx=.o)

$(SWIG_GO_SOURCES) : _cgo_export.c $(SWIG_DEF)
	mkdir -p src/github.com/griddb
	ln -s `pwd`/src `pwd`/src/github.com/griddb/go_client
	$(SWIG) -D$(CLIENT_TYPE) -outdir src/github.com/griddb/go_client/ -o $@ -c++ -go -cgo -use-shlib -intgosize 64 $(SWIG_DEF)
	sed -i "/^\#undef intgo/iextern void freeFieldDataForRow(uintptr_t data);\nextern void freeColumnInfo(uintptr_t data);\nextern void freeQueryEntryGet(uintptr_t data);\nextern void freePartitionConName(uintptr_t data);\nextern void freeStoreMultiGet(uintptr_t data);" src/griddb_go.go
	sed -i "/^import \"C\"/i// #cgo CXXFLAGS: -DGRIDDB_GO -std=c++0x -I$$\{SRCDIR\}/../include\n// #cgo LDFLAGS: -L$$\{SRCDIR\}/../libs -lrt -lgridstore\n// #include <stdlib.h>" src/griddb_go.go

.cpp.o:
	$(CXX) $(CPPFLAGS) -c -o $@ $(INCLUDES) $<

$(SWIG_GO_OBJS): $(SWIG_GO_SOURCES)
	$(CXX) $(CPPFLAGS_GO) -c -o $@ -lstdc++ $<

griddb_go.so: $(OBJS) $(SWIG_GO_OBJS)
	$(CXX) -shared  -o $@ $(OBJS) src/_cgo_export.o $(SWIG_GO_OBJS) $(LDFLAGS) $(LDFLAGS_GO)
	go install github.com/griddb/go_client

_cgo_export.c: src/callBack.go
	go tool cgo src/callBack.go
	$(CXX) -shared  -o src/_cgo_export.o _obj/_cgo_export.c $(CPPFLAGS)

clean:
	rm -rf $(OBJS) $(SWIG_GO_OBJS)
	rm -rf $(SWIG_GO_SOURCES)
	rm -rf $(PROGRAM) $(EXTRA)
	rm -rf src/github.com _obj src/_cgo_export.o
	go clean
