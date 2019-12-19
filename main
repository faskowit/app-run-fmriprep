#!/bin/bash
#PBS -l nodes=1:ppn=8,walltime=6:00:00,vmem=14gb
#PBS -N fmriprep

set -x
set -e

#write out *plugin* configuration for fmriprep to limit mem/cpus
#this can't prevent the fmriprep/nipype bootup vmem spiking (could kill the job)
cat <<EOF > multi_proc.yml
plugin: LegacyMultiProc
plugin_args: {maxtasksperchild: 1, memory_gb: 14, n_procs: 8, raise_insufficient: false}
EOF

source bids_funcs.sh

WORKDIRNAME=fmripworkdir
outdir=fmripout
INDIRNAME=fmripinput

# manually change "subject" in config.json to "TTTEMPSUB" to work with fMRIPrep

cat config.json | jq '._inputs[].meta.subject="TTTEMPSUB"' > tmp1.json
cat tmp1.json | jq '._inputs[].meta.session="SSSES"' > tmp2.json
cat tmp2.json | jq '._inputs[].meta.run="1"' > tmp3.json

mv tmp3.json config.json 

################################################################################
# read input from config.json
# starting off with basic options here

inT1w=`jq -r '.t1' config.json`
inT2w=`jq -r '.t2' config.json`
inFMRI=`jq -r '.fmri' config.json`
inFSDIR=`jq -r '.fsin' config.json`

# templates to be resampled to
#templates_bool=(`jq -r '.["T1w:res-2"], .["MNI152NLin2009cAsym"], .["fsaverage:den-10k"]' config.json`)
#template_names=("T1w:res-2" "MNI152NLin2009cAsym" "fsaverage:den-10k")
#outTEMPLATES="T1w MNI152NLin2009cAsym:res-2" # T1w and MNI152NLin2009cAsym:res-2 are required
#for i in {0..2}
#  do if ${templates_bool[$i]}; then
#    outTEMPLATES=$(echo "$outTEMPLATES" "${template_names[$i]}")
#  fi
#done

#https://fmriprep.readthedocs.io/en/stable/usage.html
#Standard and non-standard spaces to resample anatomical and functional images to. 
#Standard spaces may be specified by the form <TEMPLATE>[:res-<resolution>][:cohort-<label>][...], 
#   where <TEMPLATE> is a keyword (valid keywords: 
#   “MNI152Lin”, 
#   “MNI152NLin2009cAsym”, 
#   “MNI152NLin6Asym”, 
#   “MNI152NLin6Sym”, 
#   “MNIInfant”, 
#   “MNIPediatricAsym”, 
#   “NKI”, 
#   “OASIS30ANTs”, 
#   “PNC”, 
#   “fsLR”, 
#   “fsaverage”
#) or path pointing to a user-supplied template, and may be followed by optional, colon-separated parameters. 
#Non-standard spaces (valid keywords: 
#   anat, 
#   T1w, 
#   run, 
#   func, 
#   sbref, 
#   fsnative) 
#imply specific orientations and sampling grids. Important to note, the res-* modifier does not define the resolution used for the spatial normalization. For further details, please check out https://fmriprep.readthedocs.io/en/1.5.0/spaces.html

#https://github.com/templateflow/templateflow
#spaces=""
#$(jq -r .space_t1w config.json) && spaces="$spaces anat"
#$(jq -r .space_t1w_res2 config.json) && spaces="$spaces T1w:res-2"
#$(jq -r .space_mni152_res2 config.json) && spaces="$spaces MNI152NLin2009cAsym:res-2"
#$(jq -r .space_mni152_2009c config.json) && spaces="$spaces MNI152NLin2009cAsym"
#$(jq -r .space_fsaverage_den10k config.json) && spaces="$spaces fsaverage:den-10k"

# manually set spaces!
#spaces="MNI152NLin2009cAsym:res-2 fsaverage5"

# some logical checks
if [[ $inT1w = "null" ]] || [[ $inFMRI = "null" ]] ; then
	echo "app needs minimally a T1w and fmri. exiting"
	exit 1
fi

# extract info from brainlife interface, base on T1w
# get the staging dir, this is where meta information is 
stagingDir=$(dirname $inT1w)
echo "ls dir where initial bl info read--> $stagingDir"
ls -dl $stagingDir

if [[ $stagingDir = "." ]]; then
   echo "error finding staging directory. exiting"
   exit 1
fi

jq '._inputs[] | select(.id == "t1w")' config.json > t1w.json
blJSON=t1w.json
bidsSub="sub-TTTEMPSUB"
ses="SSSES"

################################################################################
# setup bids dir structure

rm -rf $INDIRNAME && mkdir -p $INDIRNAME
rm -rf $WORKDIRNAME && mkdir -p $WORKDIRNAME
rm -rf $outdir && mkdir -p $outdir

# the bids dir will be inside ouf input
bidsDir=$INDIRNAME
bidsSubDir=$bidsDir/$bidsSub
bidsSubSesDir=$bidsSubDir/ses-$ses
mkdir -p $bidsSubSesDir

# if freesurfer provided, copy it to the same level as output dir
# TODO why can't we just symlink this in?
if [[ $inFSDIR != "null" ]] ; then

	mkdir -p $outdir/freesurfer

	# dont know if dir will be just inFSDIR or inFSDIR/output
	if [[ -d $inFSDIR/output ]] ; then
		cp -r $inFSDIR/output $outdir/freesurfer/$bidsSub
	else
		cp -r $inFSDIR $outdir/freesurfer/$bidsSub
	fi
fi

cat > $bidsDir/dataset_description.json << 'BIDSDESCRIPT'
{
    "Name": "temp",
    "BIDSVersion": "1.0.0"
}
BIDSDESCRIPT

################################################################################
# T1w 

mkdir -p $bidsSubSesDir/anat
blJSON_T1w=t1w.json
name_T1w=$bidsSubSesDir/anat/$bidsSub
name_T1w=$(bids_namekeyvals $name_T1w $blJSON_T1w "acq ce rec run" $ses )
cp $inT1w ${name_T1w}_T1w.nii.gz
jq -r ".meta" $blJSON_T1w > ${name_T1w}_T1w.json
bids_phaseencode_check ${name_T1w}_T1w.json

################################################################################
# T2w 

if [[ $inT2w != "null" ]] ; then
	jq '._inputs[] | select(.id == "t2w")' config.json > t2w.json
	blJSON_T2w=t2w.json
	name_T2w=$bidsSubSesDir/anat/$bidsSub
	name_T2w=$(bids_namekeyvals $name_T2w $blJSON_T2w "acq ce rec run" $ses )
	cp $inT2w ${name_T2w}_T2w.nii.gz
	jq -r ".meta" $blJSON_T2w > ${name_T2w}_T2w.json
	bids_phaseencode_check ${name_T2w}_T2w.json 
fi

################################################################################
# FMRI

if [[ $inFMRI != "null" ]] ; then

	mkdir -p $bidsSubSesDir/func
	jq '._inputs[] | select(.id == "fmri")' config.json > fmri.json
	blJSON_FMRI=fmri.json
	# fmri needs task in the filename to be defined!
	name_FMRI=$bidsSubSesDir/func/$bidsSub
	name_FMRI=$(bids_namekeyvals $name_FMRI $blJSON_FMRI "task acq ce dir rec run echo" $ses )
	cp $inFMRI ${name_FMRI}_bold.nii.gz
	jq -r ".meta" $blJSON_FMRI > ${name_FMRI}_bold.json
	bids_phaseencode_check ${name_FMRI}_bold.json 

fi

################################################################################
#
# FMAP
#
# According to bids specification, we have to handle 4 fmap formats (5 if we include the new b0 "fieldmap"
#
#

#Case 1: Phase difference image and at least one magnitude image
#    Template:
#    sub-<participant_label>/[ses-<session_label>/]
#    fmap/
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_phasediff.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_phasediff.json
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_magnitude1.nii[.gz]
#
#    (optional)
#    sub-<participant_label>/[ses-<session_label>/]
#    fmap/
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_magnitude2.nii[.gz]
#    (sidecar)
#    {
#    "EchoTime1": 0.00600,
#    "EchoTime2": 0.00746,
#    "IntendedFor": "func/sub-01_task-motor_bold.nii.gz"
#    }

#Case 2: Two phase images and two magnitude images
#(fmriprep doesn't support 2phasemag https://github.com/poldracklab/fmriprep/issues/1655)
#    Template:
#    sub-<participant_label>/[ses-<session_label>/]
#    fmap/
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_phase1.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_phase1.json
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_phase2.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_phase2.json
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_magnitude1.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_magnitude2.nii[.gz]
#
#    Similar to the case above, but instead of a precomputed phase difference map two separate phase images are
#    presented. The two sidecar JSON file need to specify corresponding EchoTime values. For example:
#    {
#    "EchoTime": 0.00746,
#    "IntendedFor": "func/sub-01_task-motor_bold.nii.gz"
#    }

#Case 3: A single, real fieldmap image (showing the field inhomogeneity in each voxel)
#    Template:
#    sub-<participant_label>/[ses-<session_label>/]
#    fmap/
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_magnitude.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_fieldmap.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>][_run-<run_index>]_fieldmap.json
#
#    In some cases (for example GE) the scanner software will output a precomputed fieldmap denoting the B0
#    inhomogeneities along with a magnitude image used for coregistration. In this case the sidecar JSON file needs to
#    include the units of the fieldmap. The possible options are: “Hz”, “rad/s”, or “Tesla”. For example:
#    {
#    "Units": "rad/s",
#    "IntendedFor": "func/sub-01_task-motor_bold.nii.gz"
#    }

#Case 4: Multiple phase encoded directions (“pepolar”)
#    Template:
#    sub-<participant_label>/[ses-<session_label>/]
#    fmap/
#    sub-<label>[_ses-<session_label>][_acq-<label>]_dir-<dir_label>[_run-<run_index>]_epi.nii[.gz]
#    sub-<label>[_ses-<session_label>][_acq-<label>]_dir-<dir_label>[_run-<run_index>]_epi.json
#
#    The phase-encoding polarity (PEpolar) technique combines two or more Spin Echo EPI scans with different phase
#    encoding directions to estimate the underlying inhomogeneity/deformation map. Examples of tools using this kind
#    of images are FSL TOPUP, AFNI 3dqwarp and SPM . In such a case, the phase encoding direction is specified in the
#    corresponding JSON file as one of: “i”, “j”, “k”, “i-”, “j-, “k-”. For these differentially phase encoded sequences, one also
#    needs to specify the Total Readout Time defined as the time (in seconds) from the center of the first echo to the
#    center of the last echo (aka “FSL definition” - see here and here how to calculate it). For example
#    {
#    "PhaseEncodingDirection": "j-",
#    "TotalReadoutTime": 0.095,
#    "IntendedFor": "func/sub-01_task-motor_bold.nii.gz"
#    }
#    dir_label value can be set to arbitrary alphanumeric label ([a-zA-Z0-9]+ for example “LR” or “AP”) that can help
#    users to distinguish between different files, but should not be used to infer any scanning parameters (such as phase
#    encoding directions) of the corresponding sequence. Please rely only on the JSON file to obtain scanning
#    parameters. _epi files can be a 3D or 4D - in the latter case all timepoints share the same scanning parameters. To
#    indicate which run is intended to be used with which functional or diffusion scan the IntendedFor field in the
#    JSON file should be used.

relFMRI=$(echo ${name_FMRI}_bold.nii.gz | sed 's,.*/func/,func/,')
fieldmap_path=$(jq -r .fieldmap config.json)
fmap_in_dir=`dirname $fieldmap_path`
fmap_bids_dir=$bidsSubSesDir/fmap
name_FMAP=$fmap_bids_dir/$bidsSub
name_FMAP=$(bids_namekeyvals $name_FMAP fmap.json "acq run" $ses )

#do we really have fmap input?
if [ $fieldmap_path != "null" ]; then
	mkdir -p $fmap_bids_dir

    jq '._inputs[] | select(.id == "fmap")' config.json > fmap.json

    #can I symlink instead?
    [ -f $fmap_in_dir/phasediff.nii.gz ] && cp $fmap_in_dir/phasediff.nii.gz ${name_FMAP}_phasediff.nii.gz
    if [ -f $fmap_in_dir/phasediff.json ]; then
        cp $fmap_in_dir/phasediff.json ${name_FMAP}_phasediff.json
        bids_phaseencode_check ${name_FMAP}_phasediff.json 
		jq -r '.IntendedFor="'${relFMRI}'"' ${name_FMAP}_phasediff.json > ${name_FMAP}_phasediff.json.tmp
    fi

    [ -f $fmap_in_dir/magnitude.nii.gz ] && cp $fmap_in_dir/magnitude.nii.gz ${name_FMAP}_magnitude.nii.gz
    [ -f $fmap_in_dir/magnitude1.nii.gz ] && cp $fmap_in_dir/magnitude1.nii.gz ${name_FMAP}_magnitude1.nii.gz
    [ -f $fmap_in_dir/magnitude2.nii.gz ] && cp $fmap_in_dir/magnitude2.nii.gz ${name_FMAP}_magnitude2.nii.gz

    [ -f $fmap_in_dir/fieldmap.nii.gz ] && cp $fmap_in_dir/fieldmap.nii.gz ${name_FMAP}_fieldmap.nii.gz
    if [ -f $fmap_in_dir/fieldmap.json ]; then
        cp $fmap_in_dir/fieldmap.json ${name_FMAP}_fieldmap.json
        bids_phaseencode_check ${name_FMAP}_fieldmap.json 
		jq -r '.IntendedFor="'${relFMRI}'"' ${name_FMAP}_fieldmap.json > ${name_FMAP}_fieldmap.json.tmp
    fi

    [ -f $fmap_in_dir/phase1.nii.gz ] && cp $fmap_in_dir/phase1.nii.gz ${name_FMAP}_phase1.nii.gz
    if [ -f $fmap_in_dir/phase1.json ]; then
        cp $fmap_in_dir/phase1.json ${name_FMAP}_phase1.json
        bids_phaseencode_check ${name_FMAP}_phase1.json 
		jq -r '.IntendedFor="'${relFMRI}'"' ${name_FMAP}_phase1.json > ${name_FMAP}_phase1.json.tmp
    fi

    [ -f $fmap_in_dir/phase2.nii.gz ] && cp $fmap_in_dir/phase2.nii.gz ${name_FMAP}_phase2.nii.gz
    if [ -f $fmap_in_dir/phase2.json ]; then
        cp $fmap_in_dir/phase2.json ${name_FMAP}_phase2.json
        bids_phaseencode_check ${name_FMAP}_phase2.json 
		jq -r '.IntendedFor="'${relFMRI}'"' ${name_FMAP}_phase2.json > ${name_FMAP}_phase2.json.tmp
    fi

    #TODO - pull dir from epi1.json and epi2.json?
    epi1_dir="ap"
    epi2_dir="pa"
    #dirval=$(bids_namekeyvals "YO" fmap.json "dir" )
    #dirval=$(echo $dirval | sed s,YO_dir-,,)
    #name_FMAP_1=$(echo $name_FMAP | sed s,dir-$dirval,dir-1, )
    #name_FMAP_2=$(echo $name_FMAP | sed s,dir-$dirval,dir-2, )

    epi1name=${name_FMAP}_dir-${epi1_dir}_epi
    [ -f $fmap_in_dir/epi1.nii.gz ] && cp $fmap_in_dir/epi1.nii.gz $epi1name.nii.gz
    if [ -f $fmap_in_dir/epi1.json ]; then
        cp $fmap_in_dir/epi1.json $epi1name.json
        bids_phaseencode_check $epi1name.json
		jq -r '.IntendedFor="'${relFMRI}'"' $epi1name.json > $epi1name.json.tmp
    fi
    [ -f $fmap_in_dir/epi2.nii.gz ] && cp $fmap_in_dir/epi2.nii.gz $epi2name_pa.nii.gz
    if [ -f $fmap_in_dir/epi2.json ]; then
        cp $fmap_in_dir/epi2.json $epi2name.json
        bids_phaseencode_check $epi2name.json
		jq -r '.IntendedFor="'${relFMRI}'"' $epi2name.json > $epi2name.json.tmp
    fi

    #convert tmp file to real file
    for file in ${name_FMAP}*.tmp; do
        mv $file ${file%.tmp}
    done

    echo "fmap bids dir"
    ls -la $fmap_bids_dir
fi

    # fmap actually has a few things associated with it, hence need to copy 
    # over additional stuff: fmap is actually:
    # phasediff.nii.gz, phasediff.json, 
    # and magnitude files

    #rawPhaseDiff=$fmapDir/phasediff.nii.gz
    #rawMagnitudes=($(ls -v $fmapDir/*magnitude*nii.gz))

    #cp $rawPhaseDiff ${name_FMAP}_phasediff.nii.gz
    # replacing (or setting), the intended for category
    #jq -r '.meta | .IntendedFor="'$relFMRI'"' fmap.json > ${name_FMAP}_phasediff.json

    #for (( idx=0 ; idx<${#rawMagnitudes[@]} ; idx++ )) ; do
    #    cp ${rawMagnitudes[$idx]} ${name_FMAP}_magnitude$((idx+1)).nii.gz
    #done

    #bids_phaseencode_check ${name_FMAP}_phasediff.json 

#    elif [ -f $(jq -r .ap config.json) ] ; then
#
#		name_FMAP=$bidsSubSesDir/fmap/$bidsSub
#		name_FMAP=$(bids_namekeyvals $name_FMAP fmap.json "acq ce dir run" $ses )
#
#		# get just the direction value
#		dirval=$(bids_namekeyvals "YO" fmap.json "dir" )
#		dirval=$(echo $dirval | sed s,YO_dir-,,)
#
#		# now make the name for 1 and 2
#		name_FMAP_1=$(echo $name_FMAP | sed s,dir-$dirval,dir-1, )
#		name_FMAP_2=$(echo $name_FMAP | sed s,dir-$dirval,dir-2, )
#
#		imgs=($(ls $fmapDir/*epi*nii.gz ))
#		# if there aren't exactly two images read
#		if [[ ${#imgs[@]} -ne 2 ]] ; then
#			echo "did not read to images for fmap. exiting"
#			exit 1
#		fi
#
#		json1=$(echo ${imgs[0]} | sed s,nii.gz,json, )
#		json2=$(echo ${imgs[1]} | sed s,nii.gz,json, )
#
#		cp ${imgs[0]} ${name_FMAP_1}_epi.nii.gz
#		cp ${imgs[1]} ${name_FMAP_2}_epi.nii.gz
#		cp ${json1} ${name_FMAP_1}_epi.tmp.json
#		cp ${json2} ${name_FMAP_2}_epi.tmp.json
#
#		jq -r '.IntendedFor="'${relFMRI}'"' ${name_FMAP_1}_epi.tmp.json > ${name_FMAP_1}_epi.json
#		jq -r '.IntendedFor="'${relFMRI}'"' ${name_FMAP_2}_epi.tmp.json > ${name_FMAP_2}_epi.json
#
#		rm ${name_FMAP_1}_epi.tmp.json
#		rm ${name_FMAP_2}_epi.tmp.json
#
#		bids_phaseencode_check ${name_FMAP_1}_epi.json
#		bids_phaseencode_check ${name_FMAP_2}_epi.json
#
#	else
#		echo "problem parsing fmap. exiting"
#		exit 1
#	fi
#
#fi

###################################################################################################
#
# run fmriprep!
#

mkdir -p templateflow
export SINGULARITYENV_TEMPLATEFLOW_HOME=$PWD/templateflow

[ -z "$FREESURFER_LICENSE" ] && echo "Please set FREESURFER_LICENSE in .bashrc" && exit 1;
echo $FREESURFER_LICENSE > license.txt

space=$(jq -r .space config.json)
space_optkey="--output-spaces"
#some template can only be specified via deprecated cli option
if [ $space == "T1w" ] || [ $space == "fsaverage" ] ; then
    space_optkey="--output-space"
fi

output_space=$space
resolution=$(jq -r .resolution config.json)
if [ $resolution != "original" ];then
    output_space=$space:$resolution
fi

time singularity exec \
    -e -B $(pwd)/run.py:/usr/local/miniconda/lib/python3.7/site-packages/fmriprep/cli/run.py \
    docker://poldracklab/fmriprep:1.5.2 \
    /usr/local/miniconda/bin/fmriprep \
    --notrack \
    --resource-monitor \
    --skip-bids-validation \
    --md-only-boilerplate \
    --stop-on-first-crash \
    --use-plugin=multi_proc.yml \
    $space_optkey $output_space \
    --force-bbr \
    --use-syn-sdc \
    --fs-license-file=license.txt \
    --skull-strip-template=NKI \
    --work-dir=$WORKDIRNAME \
    --participant_label=$bidsSub \
    $bidsDir $outdir participant

echo "done with fmriprep! - now organizing output"

#####################################################################################
#
# reorganize output
#

### bold outputs ###

# get basename
inFMRI=${name_FMRI}_bold.nii.gz
oDirFunc=$outdir/fmriprep/$bidsSub/ses-${ses}/func/
outBase="$oDirFunc/$(basename $(echo $inFMRI | sed s,_bold.nii.gz,, ))"

# first of all, get the confounds
tmp=${outBase}_desc-confounds_regressors.tsv
mkdir -p output_regress
mv -v $tmp output_regress/regressors.tsv

# T1w space
# get the preproc fmri vol
tmp=${outBase}_space-${space}_desc-preproc_bold.nii.gz
mkdir -p output_bold
mv -v $tmp output_bold/bold.nii.gz

# get the preproc fmri volmask
tmp=${outBase}_space-${space}_desc-brain_mask.nii.gz
mkdir -p output_boldmask
mv -v $tmp output_boldmask/mask.nii.gz

# MNI-res2 space
#tmp=${outBase}_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
#mkdir -p output_boldMNI
#mv -v $tmp output_boldMNI/bold.nii.gz

# get the preproc fmri volmask
#tmp=${outBase}_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz
#mkdir -p output_boldmaskMNI
#mv -v $tmp output_boldmaskMNI/mask.nii.gz

# fsaverage (for the future)
#mkdir -p output_boldfsaverage
#tmp=${outBase}_space-fsaverage5_hemi-L.func.gii
#mv -v $tmp output_boldMNI/bold-L.func.gii
#tmp=${outBase}_space-fsaverage5_hemi-R.func.gii
#mv -v $tmp output_boldMNI/bold-R.func.gii

### T1w outputs ###

#inT1w=${name_T1w}_T1w.nii.gz
oDirAnat=$outdir/fmriprep/$bidsSub/anat/
outBase=$oDirAnat/$bidsSub

# get the preproc t1w vol
tmp=${outBase}_desc-preproc_T1w.nii.gz
mkdir -p output_t1
mv -v $tmp output_t1/t1.nii.gz

tmp=${outBase}_desc-brain_mask.nii.gz
mkdir -p output_t1mask
mv -v $tmp output_t1mask/mask.nii.gz

mkdir -p output_report
html=$(cd $outdir && find ./ -name "*.html")
mkdir -p output_report/$(dirname $html)
cp $outdir/$html output_report/$html
for dir in $(cd $outdir && find ./ -name figures); do
    mkdir -p output_report/$(dirname $dir)
    cp -r $outdir/$dir output_report/$(dirname $dir)
done

cat << EOF > product.json
{
    "output_bold": {
        "tags": [ "space-$space" ]
    },

    "brainlife": [
        {
            "type": "html",
            "name": "fmriprep report (todo)",
            "path": "output_report"
        }
    ]
}
EOF

# save lots of space (now that we aren't capturing raw output, I don't think this is necessary)
#rm -r $WORKDIRNAME

echo "all done"
