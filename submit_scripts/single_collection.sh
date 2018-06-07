#!/bin/bash

## How to use:
# Edit the following variables:
# <result> - Change it to the name of the collection directory you want to generate
# <EXE> <ARGS> - Replace with the executable and the arguments you're running
# <collection> - Replace with the specific collection you want to perform

if [ "$SLURM_PROCID" == "0" ]; then
	# Vtune:
	# amplxe-cl -c <collection> -r $SCRATCH/<result> -finalization-mode=deferred -- <EXE> <ARGS>

	# Advisor: Can be a single job, but VPIC needs 2 jobs
	### Combined collection, won't work for VPIC:
	# advixe-cl -c roofline -project-dir=$SCRATCH/<result> -trace-mpi -- <EXE> <ARGS>

	### Separate collection, for VPIC:
	# advixe-cl -c survey -project-dir=$SCRATCH/<result> -trace-mpi -- <EXE> <ARGS>
	# advixe-cl -c tripcounts -flop -no-trip-counts -project-dir=$SCRATCH/<result> -trace-mpi -- <EXE> <ARGS>

	# Inspector: (Can try mi1, mi2, and/or mi3 collections)
	# inspxe-cl -c <collection> -r $SCRATCH/<result> -no-auto-finalize -- <EXE> <ARGS>
else
	<EXE> <ARGS>

fi
