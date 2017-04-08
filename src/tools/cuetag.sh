#! /bin/sh

# cuetag.sh - tag files based on cue/toc file information
# uses cueprint output
# usage: cuetag.sh <cuefile|tocfile> [file]...

CUEPRINT=cueprint
cue_file=""

# print usage instructions
usage()
{
	echo "usage: cuetag.sh <cuefile|tocfile> [file]..."
	echo
	echo "cuetag.sh adds tags to files based on cue or toc information"
	echo
	echo "Supported formats (format extension, format name, tagging utility):"
	echo "ogg, Ogg Vorbis, vorbiscomment"
	echo "flac, FLAC, metaflac"
	echo "mp3, MP3, mp3info"
	echo "txt, Vorbis Comment Text File, tee"
	echo
	echo "cuetag.sh uses cueprint, which must be in your path"
}

# Vorbis Comments
# for FLAC and Ogg Vorbis files
vorbis()
{
	trackno=$1; shift
	file="$1"; shift
	fields="$@"

	# FLAC tagging
	#  --remove-all-tags overwrites existing comments
	METAFLAC="metaflac --remove-all-tags --import-tags-from=-"

	# Ogg Vorbis tagging
	# -w overwrites existing comments
	# -a appends to existing comments
	VORBISCOMMENT="vorbiscomment -w -c -"

	# VC text file format
	# TODO: this also outputs to stdout
	TXTFILE="tee"

	case "$file" in
	*.[Ff][Ll][Aa][Cc])
		VORBISTAG=$METAFLAC
		;;
	*.[Oo][Gg][Gg])
		VORBISTAG=$VORBISCOMMENT
		;;
	*.[Tt][Xx][Tt])
		VORBISTAG=$TXTFILE
		;;
	esac

	# space separated list of recommended standard field names
	# see http://www.xiph.org/ogg/vorbis/doc/v-comment.html
	# TRACKTOTAL is not in the Xiph recommendation, but is in common use

	if [ -z "$fields" ]; then
		fields='ARTIST PERFORMER DATE ALBUM VERSION GENRE COMPOSER COPYRIGHT LICENSE ORGANIZATION DESCRIPTION LOCATION CONTACT ISRC TRACKTOTAL TRACKNUMBER TITLE'
	else
		case $field in
			(DATE=????)
				fields=$fields' ARTIST PERFORMER DATE ALBUM VERSION GENRE COMPOSER COPYRIGHT LICENSE ORGANIZATION DESCRIPTION LOCATION CONTACT ISRC TRACKTOTAL TRACKNUMBER TITLE'
			;;
			*)
			;;
		esac
	fi
	
#	[ -n "$fields" ] ||
#	fields='ARTIST PERFORMER DATE ALBUM VERSION GENRE COMPOSER COPYRIGHT LICENSE ORGANIZATION DESCRIPTION LOCATION CONTACT ISRC TRACKTOTAL TRACKNUMBER TITLE'

	# fields' corresponding cueprint conversion characters
	# separate alternates with a space
	echo $fields

	TITLE='%t'
	VERSION=''
	ALBUM='%T'
	TRACKNUMBER='%02n'
	TRACKTOTAL='%02N'
	COMPOSER='%c %C'
	ARTIST='%p %P %c %C'
	PERFORMER='%p %P'
	COPYRIGHT=''
	LICENSE=''
	ORGANIZATION=''
	DESCRIPTION='%m'
	DATE=`sed -n 's!^REM DATE "\?\([^"]*\)"\?!\1!p' "$cue_file" | tr '\r' ' '`
	GENRE=`sed -n 's!^REM GENRE "\?\([^"]*\)"\?!\1!p' "$cue_file" | tr '\r' ' '`
	LOCATION=''
	CONTACT=''
	ISRC='%i %u'
	WASDATE='no'

	 >&2 echo $VORBISTAG "$file"
	(for field in $fields; do
		 case "$field" in
		 (DATE=*)	
				WASDATE='yes'
				>&2 echo "\t $field"
				echo "$field";;
				
		 (*=*)	
				>&2 echo "\t $field"
				echo "$field";;
		 (*)
			 value=""
			 for conv in $(eval echo \$$field); do
				 case $field in
					DATE)	value=$DATE
							WASDATE='yes'
					;;
					GENRE)	value=$GENRE
					;;
					*)	#>&2 echo "\n" $field - $CUEPRINT -n $trackno -t "$conv" "$cue_file"
						value=$($CUEPRINT -n $trackno -t "$conv\n" "$cue_file")
					;;
				 esac
				 if [ -n "$value" ]; then
					 >&2 echo  "\t$field=$value"
#					 >&2 echo "$field=$value"
					 echo "$field=$value"
					 break
				 fi
			 done
			 ;;
		 esac
	  done
	  if [ $WASDATE = 'no' ]; then
			>&2 echo "NO DATE IN CUE!!!!"
	  fi
	 ) | $VORBISTAG "$file"
	 >&2 echo
}

id3()
{
	MP3TAG=$(which mid3v2) \
		|| MP3TAG=$(which id3v2)
	if [ -z "${MP3TAG}" ]; then
		echo "error: not found '(m)id3v2'."
		exit 1
	fi

	# space separated list of ID3 v1.1 tags
	# see http://id3lib.sourceforge.net/id3/idev1.html

	fields="TITLE ALBUM ARTIST YEAR COMMENT GENRE TRACKNUMBER"

	# fields' corresponding cueprint conversion characters
	# separate alternates with a space

	TITLE='%t'
	ALBUM='%T'
	ARTIST='%p'
	YEAR=''
	COMMENT='%c'
	GENRE='%g'
	TRACKNUMBER='%n'

	for field in $fields; do
		case "$field" in
		*=*) value="${field#*=}";;
		*)
			value=""
			for conv in $(eval echo \$$field); do
				value=$($CUEPRINT -n $1 -t "$conv\n" "$cue_file")

				if [ -n "$value" ]; then
					break
				fi
			done
			;;
		esac

		if [ -n "$value" ]; then
			case $field in
			TITLE)
				$MP3TAG -t "$value" "$2"
				;;
			ALBUM)
				$MP3TAG -A "$value" "$2"
				;;
			ARTIST)
				$MP3TAG -a "$value" "$2"
				;;
			YEAR)
				$MP3TAG -y "$value" "$2"
				;;
			COMMENT)
				$MP3TAG -c "$value" "$2"
				;;
			GENRE)
				$MP3TAG -g "$value" "$2"
				;;
			TRACKNUMBER)
				$MP3TAG -T "$value" "$2"
				;;
			esac
		fi
	done
}

ape()
{
	TRACK=$1
	FILE=$2
	MP3TAG=$(dirname $0)/ApeTag
	if [ -z "${MP3TAG}" ]; then
		echo "error: not found '(m)id3v2'."
		exit 1
	fi

	# space separated list of ID3 v1.1 tags
	# see http://id3lib.sourceforge.net/id3/idev1.html
	shift
	shift
	fields="$@"
	[ -n "$fields" ] || 
	fields="TITLE ALBUM ARTIST YEAR DATE COMMENT GENRE"

	# fields' corresponding cueprint conversion characters
	# separate alternates with a space

	TITLE='%t'
	ALBUM='%T'
	ARTIST='%p'
	COMMENT='%c'
	DATE=`sed -n 's!^REM DATE "\?\([^"]*\)"\?!\1!p' "$cue_file" | tr '\r' ' '`
	GENRE=`sed -n 's!^REM GENRE "\?\([^"]*\)"\?!\1!p' "$cue_file" | tr '\r' ' '`
	YEAR=$DATE
	TRACKNUMBER='%n'
	if [ -z $DATE ]; then
		echo "NO DATE!!!!"
	fi
	for field in $fields; do
		case "$field" in
		*=*) value="${field#*=}";;
		*)
			value=""
			for conv in $(eval echo \$$field); do
				value=$($CUEPRINT -n $TRACK -t "$conv\n" "$cue_file")

				if [ -n "$value" ]; then
					break
				fi
			done
			;;
		esac

		if [ -n "$value" ]; then
			case $field in
			ARTIST)
				$MP3TAG """--replaceape={\"$field\":\"$value\"}""" "$FILE"
				;;
			*)
				$MP3TAG """--updateape={\"$field\":\"$value\"}""" "$FILE"
				;;
			esac
		fi
	done
}

main()
{
	if [ $# -lt 1 ]; then
		usage
		exit
	fi

	cue_file=$1
	shift

	ntrack=$(cueprint -d '%N' "$cue_file")
	trackno=1

	NUM_FILES=0 FIELDS=
	for arg in "$@"; do
		case "$arg" in
		*.*) NUM_FILES=$(expr $NUM_FILES + 1);;
		#*DATE=*) DATE="$arg";;
		#2*) DATE="$arg";;
		*) FIELDS="$FIELDS $arg";;
		esac
	done
	echo $FIELDS

	if [ $NUM_FILES -ne "$ntrack" ]; then
		echo "warning: number of files does not match number of tracks"
	fi

	for file in "$@"; do
		case $file in
		*.[Ff][Ll][Aa][Cc])
		    echo \#$trackno "$file" $FIELDS
		    vorbis $trackno "$file" $FIELDS
			;;
		*.[Oo][Gg][Gg])
			vorbis $trackno "$file" $FIELDS
			;;
		*.[Mm][Pp]3)
			id3 $trackno "$file" $FIELDS
			;;
		*.[Tt][Xx][Tt])
			vorbis $trackno "$file"
			;;
		*.[Aa][Pp][Ee])
			echo \#$trackno "$file" $FIELDS
			ape $trackno "$file" $FIELDS
			;;
		*.*)
			echo "$file: unknown file type"
			;;
		esac
		trackno=$(($trackno + 1))
	done
}

main "$@"
