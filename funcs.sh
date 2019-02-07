# helper functions

#set -e
#set -x

function checkisfile {

	inFile=$1
	if [[ ! -f ${inFile} ]] ; then
		echo "file does not exist: $inFile"
		exit 1
	fi
}

function checkisdir {

	inDir=$1
	if [[ ! -d ${inDir} ]] ; then
		echo "file does not exist: $inFile"
		exit 1
	fi
}


function bids_phaseencode_check {
	# check that any x,y,z direction is replaced with i,j,k

	inJSON=$1
	pedVal=$( jq -r ".PhaseEncodingDirection" ${inJSON} )

	if [[ ${pedVal} =~ [xyz] ]] ; then

		# brute replace
		# echo "changing the x,y,z to i,j,k"

		pedVal=$(echo ${pedVal} | sed s,x,i, )
		pedVal=$(echo ${pedVal} | sed s,y,j, )
		pedVal=$(echo ${pedVal} | sed s,z,k, )

		echo $(jq -r '.PhaseEncodingDirection="'${pedVal}'"' ${inJSON}) > ${inJSON}

	fi

}


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