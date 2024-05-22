 #!/bin/bash
 # @echo off

# setlocal
build_type=$2
runnable=RayTracer
out_name=out.jpg

if [[ $1 == "clean" ]];
then
    echo Cleaning...
    rmdir /S /Q bin
elif [[ $1 == "build-and-run" ]];
then
    echo Running $1 in $build_type mode...
    jai build.jai - $build_type && ./bin/$build_type/$runnable
    imv $out_name

elif [[ $1 == "run" ]];
then
    echo Running $1 in $build_type mode...
    ./bin/$build_type/$runnable
    imv $out_name

elif [[ $1 == "build" ]];
then
    echo Running $1 in $build_type mode...
    jai build.jai - $build_type

else 
    echo Building debug...
    jai build.jai - debug

fi

echo Done.
exit 0
