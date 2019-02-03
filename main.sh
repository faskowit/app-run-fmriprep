#!/bin/bash
#PBS -l nodes=1:ppn=8,walltime=24:00:00
#PBS -N app-run-fmriprep

EXEDIR=$(dirname "$(readlink -f "$0")")/
source ${EXEDIR}/funcs.sh

################################################################################
# read input from config.json
# starting off with basic options here

inT1w=`jq -r '.t1' config.json`
inT2w=`jq -r '.t2' config.json`
inFMRI=`jq -r '.fmri' config.json`
inFMAP=`jq -r '.fmap' config.json`
inFSDIR=`jq -r '.fsin' config.json`

################################################################################
# extract info from brainlife interface, base on T1w

# get the staging dir, this is where meta information is 
stagingDir=$(dirname ${inT1w})/
[[ ${stagingDir} = "." ]] && \
	{ echo "error finding staging directory. exiting" ; exit 1 ; }

# once we have the staging directory, we can extract some info 
blJSON=${stagingDir}/.brainlife.json
[[ ! -f ${blJSON} ]] && \
	{ echo "error finding blJSON" ; exit 1 ; }

# get the subject
sub=$(jq -r ".meta.subject" ${blJSON} )
[[ ${sub} = "null" ]] && \
	{ echo "error finding sub" ; exit 1 ; }
bidsSub="sub-$sub"

ses=$(jq -r ".meta.session" ${blJSON} )
noSes="false"
if [[ ${sub} = "null" ]] ; then
	# lets handle this
	ses=''
	noSes="true"
fi

################################################################################
# setup bids dir structure

# clean
rm -rf ${PWD}/input/ ${PWD}/ouput/
mkdir ${PWD}/input/ 
mkdir ${PWD}/ouput/

# the bids dir will be inside ouf input
bidsSubDir=${PWD}/input/${bidsSub}/
bidsSubSesDir=${bidsSubDir}/${ses}/
mkdir -p ${bidsSubSesDir}

# working dir
workdir=${PWD}/ouput/fmripworkdir/
mkdir -p ${workdir}

# output dir
outdir=${PWD}/ouput/fmripout/
mkdir ${outdir}

# if freesurfer provided, copy it to the same level as output dir
if [[ ${inFSDIR} != "null" ]] ; then

	# dont know if dir will be just inFSDIR or inFSDIR/output
	if [[ -d ${inFSDIR}/output ]] ; then
		cp -v ${inFSDIR}/output/ ${outdir}/${bidsSub}/
	else
		cp -v ${inFSDIR} ${outdir}/${bidsSub}/
	fi
fi

################################################################################
# T1w 

mkdir -p ${bidsSubSesDir}/anat
blJSON_T1w=$(dirname ${inT1w})/.brainlife.json
name_T1w="${bidsSubSesDir}/anat/${bidsSub}"
name_T1w=$(bids_namekeyvals ${name_T1w} ${blJSON_T1w} "acq ce rec run" ${ses} )
cp ${inT1w} ${name_T1w}_T1w.nii.gz
jq -r ".meta" ${blJSON_T1w} > ${name_T1w}_T1w.json

################################################################################
# T2w 

if [[ ${inT2w} != "null" ]] ; then

	blJSON_T2w=$(dirname ${inT2w})/.brainlife.json
	name_T2w="${bidsSubSesDir}/anat/${bidsSub}"
	name_T2w=$(bids_namekeyvals ${name_T2w} ${blJSON_T2w} "acq ce rec run" ${ses} )
	cp ${inT2w} ${name_T2w}_T2w.nii.gz
	jq -r ".meta" ${blJSON_T2w} > ${name_T2w}_T2w.json

fi

################################################################################
# FMRI

if [[ ${inFMRI} != "null" ]] ; then

	mkdir -p ${bidsSubSesDir}/func/
	blJSON_FMRI=$(dirname ${inFMRI})/.brainlife.json
	name_FMRI="${bidsSubSesDir}/func/${bidsSub}"
	name_FMRI=$(bids_namekeyvals ${name_FMRI} ${blJSON_FMRI} "task acq ce dir rec run echo" ${ses} )
	cp ${inFMRI} ${name_FMRI}_bold.nii.gz
	jq -r ".meta" ${blJSON_FMRI} > ${name_FMRI}_bold.json

fi

################################################################################
# FMAP

if [[ ${inFMAP} != "null" ]] ; then

	mkdir -p ${bidsSubSesDir}/fmap/
	blJSON_FMAP=$(dirname ${inFMAP})/.brainlife.json
	#blJSON_FMAP=${inFMAP}/.brainlife.json
	name_FMAP="${bidsSubSesDir}/fmap/${bidsSub}"
	name_FMAP=$(bids_namekeyvals ${name_FMAP} ${blJSON_FMAPI} "acq run" ${ses} )

	# fmap actually has a few things associated with it, hence need to copy 
	# over additional stuff: fmap is actually:
	# phasediff.nii.gz, phasediff.json, 
	# and magnitude files

	fmapDir=$(dirname ${inFMAP})/

	rawPhaseDiff=${fmapDir}/phasediff.nii.gz
	rawMagnitudes=($(ls -v ${fmapDir}/*magnitude*nii.gz))

	cp ${rawPhaseDiff} ${name_FMAP}_phasediff.nii.gz
	# replacing (or setting), the intended for category
	jq -r '.meta | .IntendedFor="'${name_FMAP}_bold.nii.gz'"' ${blJSON_FMAP} \
		> ${name_FMAP}_phasediff.json

	for (( idx=0 ; idx<${#rawMagnitudes[@]} ; idx++ )) ; do
		curMag=${rawMagnitudes[${idx}]}
		cp ${curMag} ${name_FMAP}_magnitude$((idx+1)).nii.gz
	done

fi

################################################################################
# runit

FMRIPVER=1.2.6-1
MEMGB=28
NPROC=8
OPENMPPROC=4

cat <<EOF > ${PWD}/multi_proc.yml
plugin: LegacyMultiProc
plugin_args: {maxtasksperchild: 1, memory_gb: $(echo ${MEMGB}), n_procs: $(echo ${NPROC}), raise_insufficient: false}
EOF

cmd="singularity run --cleanenv \
		docker://poldracklab/fmriprep:${FMRIPVER} \
		\
		--notrack --resource-monitor --skip_bids_validation \
		--use-plugin=${PWD}/multi_proc.yml \
		--omp-nthreads=${OPENMPPROC} \
		\
		--output-space fsaverage5 fsnative T1w template \
		--template-resampling-grid=2mm \
		--force-bbr \
		--skull-strip-template=OASIS \
		--use-syn-sdc --force-bbr --force-syn \
		\
		--fs-license-file=${FS_LICENSE} \
		\
		--work-dir=${PWD}/working/ \
		\
		--participant_label=${bidsSub} \
		\
		${bidsDir} ${PWD}/output/fmripOut/ participant \
    "
eval $cmd

#exit code from the last command (singularity) will be used.
exit $?

