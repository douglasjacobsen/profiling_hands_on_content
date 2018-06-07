# How to finalize performance data that is collected on a KNL
-------------------------------------------------------------

Some background. The CPUs on KNL are slower than traditional Xeon cores (i.e.
Haswell / Broadwell / Skylake / etc.).

Finalization of Intel tools data happens in serial currently, and as a result
of the slower cores the finalization process can take a long time if performed
on the KNL.

As a reuslt, when you collect data on KNL, you generally want to disable
finalization as part of the collection. Then you can finalize on a haswell
after the fact to speed up the process.

Below are notes for how to finalize results from the different tools.

## VTune:
---------

In order to finalize a VTune collection, one uses the following command:

`amplxe-cl -finalize -r <result> -search-dir=<path_to_objs_and_exe> -source-search-dir=<path_to_src>`

`<result>` is replaced with the path to the result directory you want to finalize.

Multiple `-search-dir` and `-source-search-dir` flags can be passed, if there
are object, source, and/or executable files located in multiple locations. Each
of these locations is processed recursively.


## Advisor:
-----------

With advisor, finalization has to happen as part of a step. In this case, we
tell it to report a survey of the code, and finalize at the same time. This
happens with the following command:

`advixe-cl -report survey -refinalize-survey -search-dir=all:r=<path_to_src/obj/exe> --project-dir=<result>`

`<result>` is replaced with the path to the result directory you want to finalize.

Multiple `-search-dir` flags can be passed. See `advixe-cl -help report` for
the syntax of the `-search-dir` flag.

## Inspector:
-------------

In order to finalize an Inspector collecction, one uses the following command:

`inspxe-cl -finalize -r <result> -search-dir=all:r=<path_to_objs_and_exe>`

`<result>` is replaced with the path to the result directory you want to finalize.

Multiple `-search-dir` flags can be passed. See `inspxe-cl -help finalize` for
the syntax of the `-search-dir` flag.

