#!/bin/bash
#SBATCH -q debug
#SBATCH --perf=vtune
#SBATCH -t 00:30:00
#SBATCH -N 1
#SBATCH -C haswell
#SBATCH -J haswell_job
#SBATCH -o haswell_job.o%j

module load vtune advisor/2018.integrated_roofline.up1 inspector/2018.up2

THREADS=16
NPROCS=1

# Setup OpenMP variables
export OMP_NUM_THREADS=$THREADS

# Write profile command:

# Aps:
# srun -n ${NPROCS} --cpu_bind=cores -- aps -- <EXE> <ARGS>

# Vtune:
# srun -n ${NPROCS} --cpu_bind=cores -- amplxe-cl -c <collection> -r $SCRATCH/<result> -- <EXE> <ARGS>

# Advisor: Can be a single job, but VPIC needs 2 jobs
### Combined collection, won't work for VPIC:
# srun -n ${NPROCS} --cpu_bind=cores -- advixe-cl -c roofline -project-dir=$SCRATCH/<result> -trace-mpi -- <EXE> <ARGS>

### Separate collection, for VPIC:
# srun -n ${NPROCS} --cpu_bind=cores -- advixe-cl -c survey -project-dir=$SCRATCH/<result> -trace-mpi -- <EXE> <ARGS>
# srun -n ${NPROCS} --cpu_bind=cores -- advixe-cl -c tripcounts -flop -no-trip-counts -project-dir=$SCRATCH/<result> -trace-mpi -- <EXE> <ARGS>

# Inspector: (Can try mi1, mi2, and/or mi3 collections)
# srun -n ${NPROCS} --cpu_bind=cores -- inspxe-cl -c <collection> -r $SCRATCH/<result> -- <EXE> <ARGS>

# Using a separate collection script
# srun -n ${NPROCS} --cpu_bind=cores -- ./single_collection.sh
