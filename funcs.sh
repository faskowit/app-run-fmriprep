# helper functions

function bids_namekeyvals {

	local baseName=$1
    local inJSON=$2
    local inPARAMS="${3}"
    # let's just take in session
    local session=$4

	# ses added manually
	if [[ -n ${ses} ]] ; then
		baseName="${baseName}_ses-${ses}"
	fi

	for addparam in ${inPARAMS} ; do

		# be flexible for fullname
		fullname=$(bids_short_to_fullname ${addparam})

		tmpval=$( jq -r ".meta.${addparam}" ${inJSON} )
		if [[ ${tmpval} = "null" ]] ; then
			# if a fullname exists, try once more
			if [[ -n ${fullname} ]] ; then
				tmpval=$( jq -r ".meta.${fullname}" ${inJSON} )
			fi
		fi

		# add to basename
		if [[ ${tmpval} != "null" ]] ; then
			baseName="${baseName}_${addparam}-${tmpval}"
		fi	

	done

	# output the basename
	echo "${baseName}"

}

# MIGHT NOT NEED THESE SPECIFIC FUNCS

function bids_anat_namekeyvals {

    # sub-<label>[_ses-<label>][_acq-<label>][_ce-<label>][_rec-<label>][_run-<index>]_<modality_label>.nii[.gz]

	local baseName=$1
    local inJSON=$2
    # let's just take in session
    local session=$3

	# ses added manually
	if [[ -n ${ses} ]] ; then
		baseName="${baseName}_ses-${ses}"
	fi

	for addparam in acq ce rec run ; do

		# be flexible for fullname
		fullname=$(bids_short_to_fullname ${addparam})

		tmpval=$( jq -r ".meta.${addparam}" ${inJSON} )
		if [[ ${tmpval} = "null" ]] ; then
			# if a fullname exists, try once more
			if [[ -n ${fullname} ]] ; then
				tmpval=$( jq -r ".meta.${fullname}" ${inJSON} )
			fi
		fi

		# add to basename
		if [[ ${tmpval} != "null" ]] ; then
			baseName="${baseName}_${addparam}-${tmpval}"
		fi	

	done

	# output the basename
	echo "${baseName}"

}

function bids_func_namekeyvals {

    # sub-<label>[_ses-<label>]_task-<label>[_acq-<label>][_ce-<label>][_dir-<label>][_rec-<label>][_run-<index>][_echo-<index>]_<contrast_label>.nii[.gz]

	local baseName=$1
    local inJSON=$2
    # let's just take in session
    local session=$3

	# ses added manually
	if [[ -n ${ses} ]] ; then
		baseName="${baseName}_ses-${ses}"
	fi

	for addparam in task acq ce dir rec run echo ; do

		# be flexible for fullname
		fullname=$(bids_short_to_fullname ${addparam})

		tmpval=$( jq -r ".meta.${addparam}" ${inJSON} )
		if [[ ${tmpval} = "null" ]] ; then
			# if a fullname exists, try once more
			if [[ -n ${fullname} ]] ; then
				tmpval=$( jq -r ".meta.${fullname}" ${inJSON} )
			fi
		fi

		# add to basename
		if [[ ${tmpval} != "null" ]] ; then
			baseName="${baseName}_${addparam}-${tmpval}"
		fi	

	done

	# output the basename
	echo "${baseName}"

}


function bids_fmap_namekeyvals {

	# right now fmriprep only supports: Phase difference image and at least one magnitude image

	# sub-<label>[_ses-<label>][_acq-<label>][_run-<index>]_phasediff.nii[.gz]
	# sub-<label>[_ses-<label>][_acq-<label>][_run-<index>]_phasediff.json
	# sub-<label>[_ses-<label>][_acq-<label>][_run-<index>]_magnitude1.nii[.gz]

	local baseName=$1
    local inJSON=$2
    # let's just take in session
    local session=$3

	# ses added manually
	if [[ -n ${ses} ]] ; then
		baseName="${baseName}_ses-${ses}"
	fi

	for addparam in acq run ; do

		# be flexible for fullname
		fullname=$(bids_short_to_fullname ${addparam})

		tmpval=$( jq -r ".meta.${addparam}" ${inJSON} )
		if [[ ${tmpval} = "null" ]] ; then
			# if a fullname exists, try once more
			if [[ -n ${fullname} ]] ; then
				tmpval=$( jq -r ".meta.${fullname}" ${inJSON} )
			fi
		fi

		# add to basename
		if [[ ${tmpval} != "null" ]] ; then
			baseName="${baseName}_${addparam}-${tmpval}"
		fi	

	done

	# output the basename
	echo "${baseName}"

}


function bids_short_to_fullname {

	# populate with fullnames. will only work with 1to1 mappings

	inShort=$1
	outFull=''

	case ${inShort} in
    	acq )
        	outFull="acquisition" ;;
    	rec )
        	outFull="reconstruction" ;;
        dir )
        	outFull="direction" ;;
	esac

	echo "$outFull"

}