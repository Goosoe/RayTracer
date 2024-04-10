REM @eIMAGE_X, IMAGE_Ycho off

setlocal
set build_type=%2%
set exe_name=RayTracer.exe
set out_name=out.jpg

if "%1"=="clean" (

    echo Cleaning...
    rmdir /S /Q bin

) else if "%1"=="build-and-run" (

    echo Running %build_type%...
    jai build.jai - %build_type% && bin\%build_type%\%exe_name%
    .\%out_name%

) else if "%1"=="run" (

    echo Running %build_type%...
    bin\%build_type%\%exe_name%
    CactusViewer.exe %~dp0\%out_name%

) else if "%1"=="build" (

    echo Building %build_type%...
    jai build.jai - %build_type%

) else (

    echo Building debug...
    jai build.jai - debug

)

echo Done.
exit /b
