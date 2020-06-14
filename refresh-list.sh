#!/usr/bin/env bash


set -e

CHECKSUM="$1"
CHECKSUM="sha1"

if [ -z "$1" ];
then
	echo "missing CHECKSUM value"
	exit 1
fi
	

DEST_FILENAME="$2"
SRC_URL="$3"

if [ -z "$2" ];
then
	echo "missing DESTFILE NAME value"
	exit 1
fi

if [ -z "$3" ];
then
	echo "missing URL value"
	exit 1
fi

wget "${SRC_URL}" -O "${DEST_FILENAME}.in" -o /dev/null
RETVAL="$?"

if [ "${RETVAL}" -ne "0" ];
then
	echo "Error download the URL ${SRC_URL}"
	exit 5
fi

OLD_CHECKSUM=""
NEW_CHECKSUM=""
if [ -f "${DEST_FILENAME}" ];
then
  if [ -f "${DEST_FILENMAE}.sha1" ];
  then
	  echo "LOCAL SHA1 CHECKSUM FILE EXISTS"
	  OLD_CHECKSUM=$(cat "${DEST_FILENAME}.sha1" | cut -d ' ' -f 1 )
  else
     sha1sum "${DEST_FILENAME}" |tee "${DEST_FILENAME}.sha1"
     OLD_CHECKSUM=$(cat "${DEST_FILENAME}.sha1" | cut -d ' ' -f 1)
  fi
else
  sha1sum "${DEST_FILENAME}.in" |tee "${DEST_FILENAME}.in.sha1"
  mv "${DEST_FILENAME}.in" "${DEST_FILENAME}" && \
  mv "${DEST_FILENAME}.in.sha1" "${DEST_FILENAME}.sha1" && \
  echo "New file installed."
  exit 0
fi

echo "OLD_CHECKSUM: ${OLD_CHECKSUM}"

sha1sum "${DEST_FILENAME}.in" |tee "${DEST_FILENAME}.in.sha1"
NEW_CHECKSUM=$(cat "${DEST_FILENAME}.in.sha1" | cut -d ' ' -f 1)


if [ "$OLD_CHECKSUM" == "$NEW_CHECKSUM" ];
then
	    echo "Old and new files are the same"
            rm -v "${DEST_FILENAME}.in" && \
            rm -v "${DEST_FILENAME}.in.sha1" && \
	    exit 10
else
	set +e
	mv "${DEST_FILENAME}" "${DEST_FILENAME}.old" && \
	mv "${DEST_FILENAME}.sha1" "${DEST_FILENAME}.old.sha1"

	set -e
	mv "${DEST_FILENAME}.in" "${DEST_FILENAME}" && \
	mv "${DEST_FILENAME}.in.sha1" "${DEST_FILENAME}.sha1" && \
	echo "Updated local file"
	exit 0
fi

set +e
