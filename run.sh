#!/bin/bash

echo "reading command line args"

inT1w="null"
inT2w="null"
inFMRI="null"
inFSDIR="null"
inODIR="null"
inWDIR="null"

while [ "$1" != "" ]; do
    case $1 in
        -t1 | -t1w )           	shift
                                inT1w=$1
                                checkisfile $1
                                ;;
        -t2 | -t2w )    		shift
                                inT2w=$1
                                checkisfile $1
                                ;;
        -fmri | -func )    		shift
                                inFMRI=$1
                                checkisfile $1
                                ;;
        -fs | -freesurfer )		shift
                                inFSDIR=$1
                                checkisdir $1
                                ;;
        -inodir )				shift
                                inODIR=$1
                                checkisdir $1
                                ;;
        -inwdir )				shift
                                inWDIR=$1
                                checkisdir $1
                                ;;
        -img | -sing )			shift
                                CMDLINESINGIMG=$1
                                checkisfile $1
                                ;;	        
        -testscript )			# no shift needed here
                                TESTINGSCRIPT="true"
                                ;;
        -testrun )				# no shift needed here
                                TESTINGRUN="true"
                                ;;  	                        
        -h | --help )           echo "see script"
                                exit 1
                                ;;
        * )                     echo "see script"
                                exit 1
    esac
    shift
done

#TODO - construct config.json from input parameters given

#brainlife expects $FREESURFER_LICENSE to be set to the content of license.txt (in a single line)
#TODO - not tested
if [[ -n $FREESURFER_HOME ]] ; then
    export FREESURFER_LICENSE=$(cat $FREESURFER_HOME/license.txt)
fi

#finally run ./main for brainlife
./main


