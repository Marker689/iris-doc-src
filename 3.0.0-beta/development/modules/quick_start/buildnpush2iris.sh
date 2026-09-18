#!/bin/bash
# Courtesy of SOCFortress

# Help
Help()
{
   # Display Help
   echo "This script builds the DFIR-IRIS module of the current directory and installs it to DFIR-IRIS. If you run it for the first time or change something in the module configuration template make sure to run the -a switch."
   echo
   echo "Syntax: $0 [-a|h][-w NAME][-p NAME]"
   echo "options:"
   echo " -a         Also install the module to the app container. Only required on initial install or when changes to config template were made."
   echo " -w NAME    Allow to specify the IRIS worker container name. By default, uses iriswebapp_worker."
   echo " -p NAME    Allow to specify the IRIS web app container name. By default uses iriswebapp_app. Only necessary if -a is also used."
   echo " -h         Print this Help."
   echo
}

CheckPrerequisite()
{
    PYTHON=$(command -v python3 || command -v python)

    if [ -z "$PYTHON" ]; then
        echo "Python could not be found"
        exit 1
    fi

    if ! python3 -m pip show wheel > /dev/null 2>&1; then
        echo "ERROR: Python package 'wheel' is required but not installed."
        echo "Please install it using: pip install wheel"
        exit 1
    fi
}

Run()
{
    CheckPrerequisite

    echo "[BUILDnPUSH2IRIS] Starting the build and push process.."
    SEARCH_DIR='./dist'
    get_recent_file () {
        FILE=$(ls -Art1 ${SEARCH_DIR} | tail -n 1)
        if [ ! -f ${FILE} ]; then
            SEARCH_DIR="${SEARCH_DIR}/${FILE}"
            get_recent_file
        fi
        echo $FILE
        exit
    }

    $PYTHON setup.py bdist_wheel

    latest=$(get_recent_file)
    module=${latest#"./dist/"}

    echo "[BUILDnPUSH2IRIS] Found latest module file: $latest"
    echo "[BUILDnPUSH2IRIS] Copy module file to worker container.."
    docker cp $latest $worker_container_name:/iriswebapp/dependencies/$module
    echo "[BUILDnPUSH2IRIS] Installing module in worker container.."
    docker exec -it $worker_container_name sh -c "pip3 install dependencies/$module --force-reinstall"
    echo "[BUILDnPUSH2IRIS] Restarting worker container.."
    docker restart $worker_container_name

    if [ "$a_Flag" = true ] ; then
        echo "[BUILDnPUSH2IRIS] Copy module file to app container.."
        docker cp $latest $app_container_name:/iriswebapp/dependencies/$module
        echo "[BUILDnPUSH2IRIS] Installing module in app container.."
        docker exec -it $app_container_name sh -c "pip3 install dependencies/$module --force-reinstall"
        echo "[BUILDnPUSH2IRIS] Restarting app container.."
        docker restart $app_container_name
    fi

    echo "[BUILDnPUSH2IRIS] Completed!"
}

a_Flag=false
worker_container_name="iriswebapp_worker"
app_container_name="iriswebapp_app"

while getopts ":haw:p:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      a) # Enter a name
         a_Flag=true
         ;;
      w) # Set custom worker container name
         worker_container_name=$OPTARG
         ;;
      p) # Set custom app container name
         app_container_name=$OPTARG
         ;;
      \?) # Invalid option
         echo "ERROR: Invalid option"
         exit 1;;
      :) # Missing argument for option
         echo "ERROR: Option -$OPTARG requires an argument."
         exit 1;;

   esac
done

if [ "$a_Flag" = true ] ; then
    echo "[BUILDnPUSH2IRIS] Pushing to Worker and App container!"
else
    echo "[BUILDnPUSH2IRIS] Pushing to Worker container only!"
fi

Run
exit
