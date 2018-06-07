#!/bin/bash

BASE_DIR=$HOME/hands_on

PROCESSORS="HSW KNL"
WORKLOADS="STREAM GUPS Tycho2 SNAP VPIC"

PROC_TYPE=HSW
PROC_TYPE=KNL

print_usage() { #{{{
	PROCESSORS=$1
	WORKLOADS=$2
	echo "setup_hands_on.sh [PROC_TYPE] [WORKLOAD]"
	echo "    PROC_TYPE = Processor type to build for. Should be one of:"
	for PROC in $PROCESSORS
	do
		echo "        $PROC"
	done
	echo "    WORKLOAD = Name of workload to setup. Shouldbe one of:"
	for WL in $WORKLOADS
	do
		echo "        $WL"
	done
} #}}}

copy_submit_scripts() { #{{{
	# This will only copy scripts if they don't already exist.

	TO_DIR=$1

	if [ ! -e ${TO_DIR}/haswell_submit.sh ]; then
		echo "Copying haswell submit script"
		cp /project/projectdirs/m3118/profiling_hands_on/submit_scripts/haswell_submit.sh ${TO_DIR}/.
	fi

	if [ ! -e ${TO_DIR}/knights_submit.sh ]; then
		echo "Copying knights landing submit script"
		cp /project/projectdirs/m3118/profiling_hands_on/submit_scripts/knights_submit.sh ${TO_DIR}/.
	fi

	if [ ! -e ${TO_DIR}/single_collection.sh ]; then
		echo "Copying knights landing submit script"
		cp /project/projectdirs/m3118/profiling_hands_on/submit_scripts/single_collection.sh ${TO_DIR}/.
	fi

	cp /project/projectdirs/m3118/profiling_hands_on/submit_scripts/finalization_notes.md ${TO_DIR}/.
} #}}}

setup_stream() { #{{{
	BASE_DIR=$1
	STREAM_ADDR=https://github.com/douglasjacobsen/stream_triad

	cd $BASE_DIR
	if [ ! -d $BASE_DIR/STREAM_Triad ]; then
		echo "Cloning stream triad"
		git clone $STREAM_ADDR STREAM_Triad &> /dev/null
	fi
	cd $BASE_DIR/STREAM_Triad
	echo "Building stream triad"
	CCOMP=CC CFLAGS="-O3 -qopenmp -qopt-report=5 -dynamic -g" make &> /dev/null

	copy_submit_scripts ${BASE_DIR}/STREAM_Triad
} #}}}

setup_gups() { #{{{
	BASE_DIR=$1
	GUPS_ADDR=https://github.com/douglasjacobsen/gups

	cd $BASE_DIR
	if [ ! -d ${BASE_DIR}/gups ]; then
		echo "Cloning gups"
		git clone ${GUPS_ADDR} ${BASE_DIR}/gups &> /dev/null
	fi

	cd $BASE_DIR/gups
	echo "Building gups"
	CC=CC make &> /dev/null

	copy_submit_scripts ${BASE_DIR}/gups
} #}}}

setup_tycho2() { #{{{
	BASE_DIR=$1
	TYCHO2_ADDR=https://github.com/LANL/Tycho2
	METIS_DIR=/project/projectdirs/m3118/profiling_hands_on/metis-5.1.0-intel

	## Setup Tycho2
	cd $BASE_DIR
	if [ ! -d $BASE_DIR/Tycho2 ]; then
		echo "Cloning Tycho2"
		git clone $TYCHO2_ADDR Tycho2 &> /dev/null
	fi

	echo "Building Tycho2 Utilities"
	cd $BASE_DIR/Tycho2/util
	cat make.inc.example | sed -e 's/CPP.*/CPP = icpc -O3 -std=c++11/' | sed -e "s/METIS_DIR.*//" > make.inc
	echo "METIS_DIR = $METIS_DIR" >> make.inc
	make PartitionMetis &> /dev/null
	make RefineSerialMesh &> /dev/null

	cd $BASE_DIR/Tycho2
	echo "Building Tycho2"
	cp make.inc.example make.inc
	if [ -e sweep.x ]; then
		make clean &> /dev/null
	fi
	echo "MPICC = CC -std=c++11 -O3 -qopenmp -qopt-report=5 -g -dynamic" >> make.inc
	make -j 4 &> tycho2_build.log

	echo "Setting up Tycho2 Input files"
	cd $BASE_DIR/Tycho2
	cat input.deck.example | sed 's/AngleP.*/AngleP     48/g' > input.deck
	./util/PartitionMetis.x 4 ./util/cube-10717.smesh cube-10717.4p.pmesh &> /dev/null

	copy_submit_scripts ${BASE_DIR}/Tycho2
} #}}}

setup_snap() { #{{{
	BASE_DIR=$1
	SNAP_ADDR=https://github.com/LANL/SNAP
	cd $BASE_DIR
	if [ ! -d $BASE_DIR/SNAP ]; then
		echo "Cloning SNAP"
		git clone $SNAP_ADDR SNAP &> /dev/null
	fi

	if [ "${PROC_TYPE}" == "HSW" ]; then
		SNAP_FLAGS="TARGET=isnap HASWELL=yes"
		SNAP_EXE=isnap
	elif [ "${PROC_TYPE}" == "KNL" ]; then
		SNAP_FLAGS="TARGET=ksnap"
		SNAP_EXE=ksnap
	fi

	cd $BASE_DIR/SNAP/src
	echo "Building ${SNAP_EXE}"
	make FORTRAN="ftn -dynamic -g" ${SNAP_FLAGS} &> /dev/null
	make clean &> /dev/null
	cp ${SNAP_EXE} ../. &>/dev/null
	cd $BASE_DIR/SNAP
	echo "Generating test.inp as an input deck for SNAP"
	cat qasnap/sample/inp | sed 's/nthreads=.*/nthreads=1/g' | sed 's/nmom=.*/nmom=4/g' | sed 's/nang=.*/nang=48/g' | sed 's/ng=.*/ng=16/g' | sed 's/nx=.*/nx=720/g' | sed 's/ichunk=.*/ichunk=24/g' > test.inp

	echo "Copying template submit scripts"
	cp /project/projectdirs/m3118/profiling_hands_on/submit_scripts/* .

	copy_submit_scripts ${BASE_DIR}/SNAP
} #}}}

setup_vpic() { #{{{
	BASE_DIR=$1
	VPIC_ADDR=https://github.com/lanl/VPIC
	cd $BASE_DIR
	if [ ! -d $BASE_DIR/VPIC ]; then
		echo "Cloning VPIC"
		git clone $VPIC_ADDR VPIC &> /dev/null
	fi
	
	if [ ! -d $BASE_DIR/VPIC/build ]; then
		mkdir $BASE_DIR/VPIC/build
	fi
	
	echo "Building VPIC"
	cd $BASE_DIR/VPIC/build
	cmake $BASE_DIR/VPIC -DCMAKE_C_COMPILER=cc -DCMAKE_CXX_COMPILER=CC -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_INTEGRATED_TESTS=OFF -DUSE_V4_SEE=ON -DCMAKE_C_FLAGS="-rdynamic -dynamic -craype-verbose -std=c99" -DCMAKE_CXX_FLAGS="-rdynamic -dynamic -craype-verbose -std=c++11" -DCMAKE_EXE_LINKER_FLAGS="-rdynamic -dynamic" &> /dev/null
	make -j 4 &> /dev/null
	echo "Building VPIC Test for 16 MPI tasks"
	cp /project/projectdirs/m3118/profiling_hands_on/vpic_input.cxx .
	./bin/vpic vpic_input.cxx &> /dev/null

	copy_submit_scripts ${BASE_DIR}/VPIC/build
} #}}}

if [ "$#" -ne 2 ]; then
	echo "Invalid number of arguments"
	print_usage "$PROCESSORS" "$WORKLOADS"
	exit
fi

PROC_TYPE=$1
WORKLOAD=$2

VALID_PROC=0
for PROC in $PROCESSORS
do
	if [ "${PROC}" == "${PROC_TYPE}" ]; then
		VALID_PROC=1
	fi
done

if [ $VALID_PROC == 0 ]; then
	echo "Invalid Processor type. Should be one of:"
	for PROC in $PROCESSORS
	do
		echo "    $PROC"
	done
	exit
fi

VALID_WL=0
for WL in $WORKLOADS
do
	if [ "${WL}" == "${WORKLOAD}" ]; then
		VALID_WL=1
	fi
done
if [ $VALID_WL == 0 ]; then
	echo "Invalid workload. Should be one of:"
	for WL in $WORKLOADS
	do
		echo "    $WL"
	done
	exit
fi

if [ ! -d $BASE_DIR ]; then
	mkdir $BASE_DIR
fi

module unload craype-haswell &> /dev/null
module unload craype-mic-knl &> /dev/null

echo "Processor type is ${PROC_TYPE}"
if [ "$PROC_TYPE" ==  "KNL" ]; then
	module load craype-mic-knl
elif [ "$PROC_TYPE" == "HSW" ]; then
	module load craype-haswell
else
	echo " Processor type of ${PROC_TYPE} unsupported."
	exit
fi

if [ "$WORKLOAD" == "STREAM" ]; then
	setup_stream $BASE_DIR
elif [ "$WORKLOAD" == "GUPS" ]; then
	setup_gups $BASE_DIR
elif [ "$WORKLOAD" == "Tycho2" ]; then
	setup_tycho2 $BASE_DIR
elif [ "$WORKLOAD" == "SNAP" ]; then
	setup_snap $BASE_DIR
elif [ "$WORKLOAD" == "VPIC" ]; then
	setup_vpic $BASE_DIR
fi


