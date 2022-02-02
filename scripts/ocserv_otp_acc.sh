#!/bin/bash
# This script generates the OTP data for the account and writes 
# this data to the file OATH_FILE='/config/auth/ocserv_usrs.oath'.
# Assumes the <account_name> parameter when called:
# ./ocserv_otp_acc.sh <account_name> 
#


USR=$1
OATH_FILE='/config/auth/ocserv_usrs.oath'
touch -a $OATH_FILE
HEX_KEY=$(head -c 4096 /dev/urandom | md5sum | awk '{print $1}')
OATH_CMD=$(oathtool --verbose --window=3 --totp $HEX_KEY)
[[ ${OATH_CMD} =~ "Base32 secret: "([[:alnum:]]*) ]] && BASE32_KEY=${BASH_REMATCH[1]}

#Generate output lines
OTP_URL="otpauth://totp/$USR@$HOSTNAME?secret=$BASE32_KEY"
qrencode -m 2 -t utf8 -o- -d 300 -s 10 "$OTP_URL"
echo "$OATH_CMD"
echo $OTP_URL

#Generate lines for OATH_FILE and add|replace if user already in file
FILELINE="HOTP/T30 $USR - $HEX_KEY"
FILELINE_ESC="HOTP\/T30 $USR - $HEX_KEY"
IF_USR_XST=$(awk "/[[:blank:]]$USR[[:blank:]]/{ print NR; exit }" ${OATH_FILE})
if [ ! -z "$IF_USR_XST" ]
then
  sed -i "${IF_USR_XST}s/.*/$FILELINE_ESC/" ${OATH_FILE}
else
  echo "$FILELINE" >>${OATH_FILE}
fi
