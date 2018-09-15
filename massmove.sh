#!/bin/bash
#/media/5f131047-b830-4d89-88f3-f139bebfdef6/DataHub/Projektmappen/Visual_Studio/Projects/massmove

export before=$(date +%s)
export CreateLogTime=$(date +%d.%m.%Y@%H-%M-%S)
export DELETEGLOBAL=0
export SERIECOUNT=0
export SEASONCOUNT=0
export EPCOUNT=0
export TESTMODUS=1
export DELONLY=0
export SEARCHPATH=""

# lege logdatei mit aktuellem Zeitstempel an
echo -e "Start der Protokollierung: $CreateLogTime\r\n" > massmove_log_$CreateLogTime.txt
echo -e "Start der Protokollierung: $CreateLogTime\r\n" > massmove_umbenannt_$CreateLogTime.txt

# lege ausgelagerten bytezähler an
echo "0" > delbytes.txt

#-----------------------------------------------------------------------------------------
# FUNKTION - Hilfsfunktion um mehr als ein return eienr methode zu erhalten
#-----------------------------------------------------------------------------------------
function GetMultipleReturn
{

    echo `echo $1 | cut -d',' -f $2`

	## function call
	#RESULT=`GetMultipleReturn`
		
	## get parts of result
	#RES1=`get_rtrn $RESULT 1`
	#RES2=`get_rtrn $RESULT 2`
	#RES3=`get_rtrn $RESULT 3`

}


#-----------------------------------------------------------------------------------------
# FUNKTION - printout
#-----------------------------------------------------------------------------------------
function printout
{

	local PRINTOUT_SERIE=$1
	local PRINTOUT_STNR=$2
	local EPNR=$3
	local PRINTOUT_DATEI=$4
	local PRINTOUT_DOPPEL=$5
	local PRNTCHECK=1
	local EPNR2
	local STRING

	echo ">>>>Printout<<<< - Wenn erfolg return 0 (True)" >&2

	if [ $PRINTOUT_DOPPEL -eq 0 ]; then

		let EPNR2=EPNR+1

		echo "*********************************************" >&2

		if [ -z $PRINTOUT_STNR ]; then

			STRING=$(printf "%s - E%02dE%02d\n" "$(basename "$PRINTOUT_SERIE")" "$EPNR" "$EPNR2")
			echo "$STRING" >&2
			ProtokolliereTaufe "2" "$PRINTOUT_DATEI" "$PRINTOUT_DATEI" "$STRING"

			PRNTCHECK=0

		else

			STRING=$(printf "%s - S%02dE%02dE%02d\n" "$(basename "$PRINTOUT_SERIE")" "$PRINTOUT_STNR" "$EPNR" "$EPNR2")
			echo "$STRING" >&2
			ProtokolliereTaufe "2" "$PRINTOUT_DATEI" "$PRINTOUT_DATEI" "$STRING"
			
			PRNTCHECK=0

		fi

		echo "*********************************************" >&2

	else

		echo "*********************************************" >&2
		if [ -z $PRINTOUT_STNR ]; then

			STRING=$(printf "%s - E%02d\n" "$(basename "$PRINTOUT_SERIE")" "$EPNR")
			echo "$STRING" >&2
			ProtokolliereTaufe "2" "$PRINTOUT_DATEI" "$PRINTOUT_DATEI" "$STRING"

			PRNTCHECK=0

		else

			STRING=$(printf "%s - S%02dE%02d\n" "$(basename "$PRINTOUT_SERIE")" "$PRINTOUT_STNR" "$EPNR")
			echo "$STRING" >&2
			ProtokolliereTaufe "2" "$PRINTOUT_DATEI" "$PRINTOUT_DATEI" "$STRING"

			PRNTCHECK=0

		fi

		echo "*********************************************" >&2

	fi

	echo ">>>>Printout<<<< - Return = $PRNTCHECK" >&2
	echo ">>>>Printout<<<< - EP Nummer = $EPNR" >&2

	return $PRNTCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Prüfe ob Doppelfolge oder nicht
#-----------------------------------------------------------------------------------------
function IfDoppelfolgeReturnTrue
{

	local DOPPEL_SERIE=$1
	local DOPPEL_STNR=$2
	local EPNR=$3
	local DOPPEL_DATEI=$4
	local DOPPEL_CHECKSTAFFEL=$5
	local DOPPELCHECK=1
	local EPNRLENGTH
	local DOPPEL_EXTFOLGE
	local EPNR2
	local STCHK

	echo ">>>>IfDoppelfolgeReturnTrue<<<< - Wenn Doppelfolge return 0 (True)" >&2

	DOPPEL_EXTFOLGE=$(EntferneUnnoetigeStringTeile "$DOPPEL_DATEI" "$DOPPEL_SERIE")

	EPNR=$(echo $EPNR | sed "s/^0*//")
	let EPNR2=EPNR+1

	#Prüfe ob dobbelfolge oder nicht
	EPNRLENGTH=${#EPNR}

	if [ "$EPNRLENGTH" -eq 3 ]; then
			echo "HIER 11 = $EPNR" >&2
		echo "$DOPPEL_EXTFOLGE" | grep -E -i "$EPNR2"
		DOPPELCHECK=$?		

		STCHK=$(echo $EPNR | cut -b 1)

		if [ "$DOPPEL_STNR" == "$STCHK" ]; then
			echo "HIER 22 = $EPNR" >&2
			EPNR2=${EPNR2:1}
			EPNR=${EPNR:1}

		fi

		EPNR=$( echo $EPNR | sed "s/^0*//" )
		EPNR2=$( echo $EPNR2 | sed "s/^0*//" )

	else

		# Suche zweite EP Nummer in Datei  
		echo "$DOPPEL_EXTFOLGE" | grep -E -i "([^a-z][efx]|ep\.?)$EPNR2"
		DOPPELCHECK=$?

		echo "HIER 0 = $EPNR" >&2
		if [ "$DOPPELCHECK" -eq 1 ]; then # Suche zweite EP Nummer in Überordner  
			echo "HIER 1 = $DOPPELCHECK" >&2
			if [ "$DOPPEL_CHECKSTAFFEL" -eq 1 ]; then
			echo "HIER 2 = $DOPPELCHECK" >&2
				DIRSTRING=$( dirname "$DOPPEL_DATEI" )
				DIRSTRING=$( basename "$DIRSTRING" )
				DIRSTRING=$(EntferneUnnoetigeStringTeile "$DIRSTRING" "$DOPPEL_SERIE")

				echo "$DIRSTRING" | grep -E -i "([^a-z][efx]|ep\.?)$EPNR2"
				DOPPELCHECK=$?

			fi

			if [ "$DOPPELCHECK" -eq 1 ]; then # Suche zweite EP Nummer in Datei aber 3 Stellig
				echo "HIER 3 = $DOPPELCHECK" >&2
				EPNR=$(basename "$DOPPEL_EXTFOLGE" | grep -E -o -i "[0-9][0-9]{0,2}" | sed q | sed "s/^0*//")

				if [[ $EPNR =~ ^[0-9]{3,3}$ ]]; then # Wenn dreistellige Nummer, dann...
					echo "HIER 4 = $DOPPELCHECK" >&2
					EPNR=$( echo $EPNR | sed "s/^0*//" )

					let EPNR2=EPNR+1

					echo "$DOPPEL_EXTFOLGE" | grep -E -i "$EPNR2"
					DOPPELCHECK=$?

					if [ "$DOPPELCHECK" -eq 1 ]; then  # Suche zweite EP Nummer in Ordner aber 3 Stellig
						echo "HIER 5 = $DOPPELCHECK" >&2
						if [ "$DOPPEL_CHECKSTAFFEL" -eq 1 ]; then
							echo "HIER 6 = $DOPPELCHECK" >&2
							EPNR=$(basename "$DIRSTRING" | grep -E -o -i "[0-9][0-9]{0,2}" | sed q | sed "s/^0*//")

							if [[ $EPNR =~ ^[0-9]{3,3}$ ]]; then # Wenn dreistellige Nummer, dann...
								echo "HIER 7 = $DOPPELCHECK" >&2
								EPNR=$( echo $EPNR | sed "s/^0*//" )

								let EPNR2=EPNR+1

								echo "$DIRSTRING" | grep -E -i "$EPNR2"
								DOPPELCHECK=$?

							fi

						fi	

					fi

				fi

			fi

		fi
		
	fi

	echo ">>>>IfDoppelfolgeReturnTrue<<<< - Return = $DOPPELCHECK" >&2
	echo ">>>>IfDoppelfolgeReturnTrue<<<< - EP Nummer 1 = $EPNR" >&2
	echo ">>>>IfDoppelfolgeReturnTrue<<<< - EP Nummer 2 = $EPNR2" >&2
	echo "$EPNR2"

	return $DOPPELCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - EPNR säubern
#-----------------------------------------------------------------------------------------
function ExtrahiereFolgennummerAusDatei
{

	local EXTRAKT_DATEI=$1
	local EXTRAKT_SERIE=$2
	local EPNRCHECK=1
	local EPNR=0
	local ORES
	local FRES
	local DIRSTRING
	
	echo ">>>>ExtrahiereFolgennummerAusDatei<<<< - Wenn gültige Nummer return 0 (True)" >&2

	EPNR=$(EntferneUnnoetigeStringTeile "$EXTRAKT_DATEI" "$EXTRAKT_SERIE")
	
	EPNR=$(echo "$EPNR" | grep -E -o -i "([0-9][0-9]\.? ?[efx]|ep\.?)[0-9][0-9]" | grep -E -o -i "([efx]|ep\.?)[0-9][0-9]" | grep -E -o "[0-9][0-9]{0,2}")
	EPNRCHECK=$?

	EPNR=$(echo $EPNR | sed q | cut -d' ' -f 1) # Nimm erste zeile
	EPNR=$(echo $EPNR | sed "s/^0*//") # Entferne führende Null

	COUNT=${#EPNR}
	if [ $COUNT -gt 2 ]; then # Wenn EPNR größer 2 wird angenommen, dass der Serienname eine Zahl enthielt. Vom String Anfang bis

		NUMBERINSERIE=$(basename "$EXTRAKT_SERIE")
		NUMBERINSERIE=${NUMBERINSERIE//[!0-9]/}

		echo "NUMBERINSERIE = $NUMBERINSERIE" >&2

		EPNR=$(echo $EPNR | sed "s/^$NUMBERINSERIE*//")

		echo "EPNR = $EPNR" >&2

	fi

	echo ">>>>ExtrahiereFolgennummerAusDatei<<<< - Return = $EPNRCHECK" >&2
	echo ">>>>ExtrahiereFolgennummerAusDatei<<<< - EP Nummer = $EPNR" >&2
	echo "$EPNR"

	return $EPNRCHECK

}
#-----------------------------------------------------------------------------------------
# FUNKTION - EPNR säubern
#-----------------------------------------------------------------------------------------
function ExtrahiereFolgennummerAusOrdner
{

	local EXTRAKT_DATEI=$1
	local EXTRAKT_SERIE=$2
	local EPNRCHECK=1
	local EPNR=0
	local ORES
	local FRES
	local DIRSTRING
	
	echo ">>>>ExtrahiereFolgennummerAusOrdner<<<< - Wenn gültige Nummer return 0 (True)" >&2

		# prüfe ob ordnername eine EP nummer enthält
		DIRSTRING=$( dirname "$EXTRAKT_DATEI" )
		DIRSTRING=$( basename "$DIRSTRING" )
		
		EPNR=$(EntferneUnnoetigeStringTeile "$DIRSTRING" "$EXTRAKT_SERIE")

		EPNR=$(echo "$EPNR" | grep -E -o -i "([efx]|ep\.?)[0-9]*" | grep -E -o "[0-9][0-9]{0,2}")
		EPNRCHECK=$?

		EPNR=$(echo $EPNR | sed q | cut -d' ' -f 1) # Nimm erste zeile
		EPNR=$(echo $EPNR | sed "s/^0*//") # Entferne führende Null

		COUNT=${#EPNR}
		if [ $COUNT -gt 2 ]; then # Wenn EPNR größer 2 wird angenommen, dass der Serienname eine Zahl enthielt. Vom String Anfang bis
		
			NUMBERINSERIE=$(basename "$EXTRAKT_SERIE")
			NUMBERINSERIE=${NUMBERINSERIE//[!0-9]/}

			echo "NUMBERINSERIE = $NUMBERINSERIE" >&2

			EPNR=$(echo $EPNR | sed "s/^$NUMBERINSERIE*//")

			echo "EPNR = $EPNR" >&2
		fi

	echo ">>>>ExtrahiereFolgennummerAusOrdner<<<< - Return = $EPNRCHECK" >&2
	echo ">>>>ExtrahiereFolgennummerAusOrdner<<<< - EP Nummer = $EPNR" >&2
	echo "$EPNR"

	return $EPNRCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - STNR säubern
#-----------------------------------------------------------------------------------------
function ExtrahiereStaffelnummer
{

	local EXTRAKT_DATEI=$1
	local EXTRAKT_SERIE=$2
	local STNRCHECK=1
	local STNR=0
	local ORES
	local SRES
	local DIRSTRING
	
	echo ">>>>ExtrahiereStaffelnummer<<<< - Wenn gültige Nummer return 0 (True)" >&2

	STNR=$(EntferneUnnoetigeStringTeile "$EXTRAKT_DATEI" "$EXTRAKT_SERIE")
	
	STNR=$(echo "$STNR" | grep -E -o -i "s[0-9][0-9]([efx]|ep\.?)" | grep -E -o "[0-9][0-9]{0,2}")
	SRES=$?

	STNR=$(echo $STNR | sed q | cut -d' ' -f 1 ) # Nimm erste zeile
	STNR=$(echo $STNR | sed "s/^0*//") # Entferne führende Null

	COUNT=${#STNR}
	if [ $COUNT -gt 2 ]; then # Wenn STNR größer 2 wird angenommen, dass der Serienname eine Zahl enthielt. Vom String Anfang bis
		NUMBERINSERIE=$(basename "$EXTRAKT_SERIE")
		NUMBERINSERIE=${NUMBERINSERIE//[!0-9]/}

		echo "NUMBERINSERIE = $NUMBERINSERIE" >&2

		STNR=$(echo $STNR | sed "s/^$NUMBERINSERIE*//")

		echo "STNR = $STNR" >&2

	fi

	if [ $SRES -eq 1 ]; then

		# prüfe ob ordnername eine EP nummer enthält
		DIRSTRING=$( dirname "$EXTRAKT_DATEI" )
		DIRSTRING=$( basename "$DIRSTRING" )
		
		STNR=$(EntferneUnnoetigeStringTeile "$DIRSTRING" "$EXTRAKT_SERIE")

		STNR=$(echo "$STNR" | grep -E -o -i "s[0-9][0-9]([efx]|ep\.?)" | grep -E -o "[0-9][0-9]{0,2}")
		ORES=$?

		STNR=$(echo $STNR | sed q  | cut -d' ' -f 1 ) # Nimm erste zeile
		STNR=$(echo $STNR | sed "s/^0*//") # Entferne führende Null

		COUNT=${#STNR}
		if [ $COUNT -gt 2 ]; then # Wenn STNR größer 2 wird angenommen, dass der Serienname eine Zahl enthielt. Vom String Anfang bis
			NUMBERINSERIE=$(basename "$EXTRAKT_SERIE")
			NUMBERINSERIE=${NUMBERINSERIE//[!0-9]/}

			echo "NUMBERINSERIE = $NUMBERINSERIE" >&2

			STNR=$(echo $STNR | sed "s/^$NUMBERINSERIE*//")

			echo "STNR = $STNR" >&2

		fi

		if [ $ORES -eq 1 ]; then

			STNRCHECK=1

		else

			STNRCHECK=0

		fi

	else

		STNRCHECK=0

	fi

	echo ">>>>ExtrahiereStaffelnummer<<<< - Return = $STNRCHECK" >&2
	echo ">>>>ExtrahiereStaffelnummer<<<< - ST Nummer = $STNR" >&2
	echo "$STNR"

	return $STNRCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION Prüfe Datei oder Ordner für Staffel
#-----------------------------------------------------------------------------------------
function PruefeDateiFuerStaffel
{

	echo ">>>>PruefeDateiFuerStaffel<<<< - Wenn gültige Datei return 0 (True)" >&2
	local PRUEFDATEI=$1
	local PRUEF_SERIE=$2
	local DATEICHECK=1
	local STNR

	if [ -d "$PRUEFDATEI" ]; then # Wenn es sich um einen Ordner handelt dann...

		echo "Datei ist Ordner: " $(basename "$PRUEFDATEI") >&2
		echo "Suche Dateien..." >&2

		while read PRUEF_FILE # Suche Dateien im Ordner
		do

			echo "Datei gefunden: " $(basename "$PRUEF_FILE") >&2

			PruefeDateiGroeßeUndTyp "$PRUEF_FILE" "ERROR" "$PRUEF_SERIE"
			if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...
				
				STNR=$(ExtrahiereStaffelnummer "$PRUEF_FILE" "$PRUEF_SERIE")
		
				if [ $? -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

					STNR=$(IfZweiOderDreiStelligReturnTrue "$PRUEFDATEI" "ERROR" "$PRUEF_SERIE")
					DATEICHECK=$?

				else

					DATEICHECK=0
				fi

			fi

		done  <<< "$(find "$PRUEFDATEI" -type f)"

	else

		echo "Datei gefunden: " $(basename "$PRUEFDATEI") >&2
		PruefeDateiGroeßeUndTyp "$PRUEFDATEI" "ERROR" "$PRUEF_SERIE"

		if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...

			STNR=$(ExtrahiereStaffelnummer "$PRUEFDATEI" "$PRUEF_SERIE")			
			if [ $? -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

				STNR=$(IfZweiOderDreiStelligReturnTrue "$PRUEFDATEI" "ERROR" "$PRUEF_SERIE")
				DATEICHECK=$?

			else

				DATEICHECK=0

			fi

		fi

	fi

	echo ">>>>PruefeDateiFuerStaffel<<<< - Return = $DATEICHECK" >&2
	echo ">>>>PruefeDateiFuerStaffel<<<< - ST Nummer = $STNR" >&2

	echo "$STNR"

	return $DATEICHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Episode herausfinden
#-----------------------------------------------------------------------------------------
function EntferneUnnoetigeStringTeile
{

	local EXTFOLGE=$(basename "$1")
	local SERIENNAME1=$(basename "$2")
	local SERIENNAME2

	echo ">>>>EntferneUnnoetigeStringTeile<<<<" >&2

	# Ersetze in String EXTFOLGE den String recht von "//" mit den string rechts von "/" (empty)
	EXTFOLGE=${EXTFOLGE//1080p/}
	EXTFOLGE=${EXTFOLGE//18p/}
	EXTFOLGE=${EXTFOLGE//720p/}
	EXTFOLGE=${EXTFOLGE//72p/}
	EXTFOLGE=${EXTFOLGE//7p/}
	EXTFOLGE=${EXTFOLGE//480p/}
	EXTFOLGE=${EXTFOLGE//1080P/}
	EXTFOLGE=${EXTFOLGE//18P/}
	EXTFOLGE=${EXTFOLGE//720P/}
	EXTFOLGE=${EXTFOLGE//72P/}
	EXTFOLGE=${EXTFOLGE//7P/}
	EXTFOLGE=${EXTFOLGE//480P/}

	EXTFOLGE=${EXTFOLGE//80AHD/}

	EXTFOLGE=${EXTFOLGE//dd51/}
	EXTFOLGE=${EXTFOLGE//dd+51/}
	EXTFOLGE=${EXTFOLGE//DD51/}
	EXTFOLGE=${EXTFOLGE//DD+51/}
	EXTFOLGE=${EXTFOLGE//5.1/}

	EXTFOLGE=${EXTFOLGE//dd20/}
	EXTFOLGE=${EXTFOLGE//dd+20/}
	EXTFOLGE=${EXTFOLGE//DD20/}
	EXTFOLGE=${EXTFOLGE//DD+20/}
	EXTFOLGE=${EXTFOLGE//2.0/}

	EXTFOLGE=${EXTFOLGE//dd71/}
	EXTFOLGE=${EXTFOLGE//dd+71/}
	EXTFOLGE=${EXTFOLGE//DD71/}
	EXTFOLGE=${EXTFOLGE//DD+71/}
	EXTFOLGE=${EXTFOLGE//7.1/}

	EXTFOLGE=${EXTFOLGE//x264/}
	EXTFOLGE=${EXTFOLGE//h264/}
	EXTFOLGE=${EXTFOLGE//x265/}
	EXTFOLGE=${EXTFOLGE//h265/}
	EXTFOLGE=${EXTFOLGE//X264/}
	EXTFOLGE=${EXTFOLGE//H264/}
	EXTFOLGE=${EXTFOLGE//X265/}
	EXTFOLGE=${EXTFOLGE//H265/}

	EXTFOLGE=${EXTFOLGE//part.1/}
	EXTFOLGE=${EXTFOLGE//Part.1/}
	EXTFOLGE=${EXTFOLGE//part.2/}
	EXTFOLGE=${EXTFOLGE//Part.2/}
	EXTFOLGE=${EXTFOLGE//part.3/}
	EXTFOLGE=${EXTFOLGE//Part.3/}
	EXTFOLGE=${EXTFOLGE//part 1/}
	EXTFOLGE=${EXTFOLGE//Part 1/}
	EXTFOLGE=${EXTFOLGE//part 2/}
	EXTFOLGE=${EXTFOLGE//Part 2/}
	EXTFOLGE=${EXTFOLGE//part 3/}
	EXTFOLGE=${EXTFOLGE//Part 3/}

	EXTFOLGE=${EXTFOLGE//teil.1/}
	EXTFOLGE=${EXTFOLGE//Teil.1/}
	EXTFOLGE=${EXTFOLGE//teil.2/}
	EXTFOLGE=${EXTFOLGE//Teil.2/}
	EXTFOLGE=${EXTFOLGE//teil.3/}
	EXTFOLGE=${EXTFOLGE//Teil.3/}
	EXTFOLGE=${EXTFOLGE//teil 1/}
	EXTFOLGE=${EXTFOLGE//Teil 1/}
	EXTFOLGE=${EXTFOLGE//teil 2/}
	EXTFOLGE=${EXTFOLGE//Teil 2/}
	EXTFOLGE=${EXTFOLGE//teil 3/}
	EXTFOLGE=${EXTFOLGE//Teil 3/}

	EXTFOLGE=${EXTFOLGE#$SERIENNAME1}
	SERIENNAME2=${SERIENNAME1,,}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}

	SERIENNAME2=${SERIENNAME1// /.}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}
	SERIENNAME2=${SERIENNAME1// /-}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}
	SERIENNAME2=${SERIENNAME1// /}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}

	SERIENNAME2=${SERIENNAME1// /.}
	SERIENNAME2=${SERIENNAME2,,}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}
	SERIENNAME2=${SERIENNAME1// /-}
	SERIENNAME2=${SERIENNAME2,,}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}
	SERIENNAME2=${SERIENNAME1// /}
	SERIENNAME2=${SERIENNAME2,,}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME2}

	echo ">>>>EntferneUnnoetigeStringTeile<<<< - Ergebnis = $EXTFOLGE" >&2

	echo "$EXTFOLGE"

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Episode herausfinden
#-----------------------------------------------------------------------------------------
function IfZweiOderDreiStelligReturnTrue
{

	local ZWEIDREI_DATEI=$1
	local ZWEIDREI_STNR=$2
	local ZWEIDREI_SERIE=$3
	local ZWEIDREICHECK=1
	local EPNR
	local STNR
	
  	echo ">>>>IfZweiOderDreiStelligReturnTrue<<<< - Wenn gültige 2 oder 3 stellige Nummer return 0 (True)" >&2
 clmb0101
	EPNR=$(EntferneUnnoetigeStringTeile "$ZWEIDREI_DATEI" "$ZWEIDREI_SERIE")
	EPNR=$(echo "$EPNR" | grep -E -o -i "[0-9]{2,4}")

	if [[ $EPNR =~ ^[0-9]{2,2}$ ]]; then # Wenn zweistellige Nummer, dann...

		EPNR=$( echo $EPNR | cut -d' ' -f 1 | sed "s/^0*//" )
		ZWEIDREICHECK=0

	else

		#EPNR=$(echo "$EPNR" | grep -E -o -i "[0-9]{3,3}")
		#EPNR=$("$EPNR" | cut -d' ' -f 1)
		if [[ $EPNR =~ ^[0-9]{3,3}$ ]]; then # Wenn dreistellige Nummer, dann...

			STNR=${EPNR:0:1} # der führende Digit ist die Staffelnummer
			EPNR=${EPNR:1}	# die letzten 2 Digits sind die folgen Nummer
			EPNR=$( echo $EPNR | sed "s/^0*//" )

			ZWEIDREICHECK=0

		else

			if [ "$ZWEIDREI_STNR" != "ERROR" ]; then # Prüfung ob IfZweiOderDreiStelligReturnTrue von PruefeDateiFuerStaffel aufgerufen wurde, wenn ja kein Logging

				SchreibeInLogdatei "$ZWEIDREI_DATEI" "$ZWEIDREI_STNR" "$ZWEIDREI_SERIE" "3" "Folgennummer konnte nicht extrahiert werden"

			fi

			ZWEIDREICHECK=1

		fi

	fi

	echo ">>>>IfZweiOderDreiStelligReturnTrue<<<< - Return = $ZWEIDREICHECK" >&2
	echo ">>>>IfZweiOderDreiStelligReturnTrue<<<< - EP Nummer = $EPNR" >&2
	echo ">>>>IfZweiOderDreiStelligReturnTrue<<<< - ST Nummer = $STNR" >&2

	if [ "$ZWEIDREI_STNR" != "ERROR" ]; then # Prüfung ob IfZweiOderDreiStelligReturnTrue von PruefeDateiFuerStaffel aufgerufen wurde, wenn ja gebe STNR aus

		echo "$EPNR"

	else

		if [ "$STNR" == "" ]; then # Prüfung ob STNR extrahiert werden konnte

			ZWEIDREICHECK=1

		fi

		echo "$STNR"

	fi

	return $ZWEIDREICHECK

}

#-----------------------------------------------------------------------------------------
# FUNKTION - Check Dateityp und Größe
#-----------------------------------------------------------------------------------------
function PruefeDateiGroeßeUndTyp
{

	local PRFDATGR_FILE=$1
	local PRFDATGR_STNR=$2
	local PRFDATGR_SERIE=$3
	local PRFDATGR_SIZE=$(PruefeDateiGroeße "$PRFDATGR_FILE") #Speichere Dateigröße in Variable
	local DATGRCHECK=1

	echo ">>>>PruefeDateiGroeßeUndTyp<<<< - Wenn Videodatei OK return 0 (True)" >&2

	PruefeDateiTyp "$PRFDATGR_FILE" # Wenn OK return 0 (True)
	DATGRCHECK=$?
	if [ $DATGRCHECK -eq 0 ]; then # Wenn der geforderte Dateityp enthalten ist überprüfe die Dateigröße

	#prüfe ob datei kein Sample ist (größe der Datei)

		if [ $PRFDATGR_SIZE -gt 20000000 ]; then # Wenn datei über 20MB groß ist dann...

			echo "Videodatei: " $(basename "$PRFDATGR_FILE") >&2
			DATGRCHECK=0

		else

			echo "Sample: " $(basename "$PRFDATGR_FILE") >&2
			DATGRCHECK=1
			
			if [ $PRFDATGR_STNR != "ERROR" ]; then # Prüfung ob PruefeDateiGroeßeUndTyp von PruefeDateiFuerStaffel aufgerufen wurde, wenn ja kein Logging und löschen

					SchreibeInLogdatei "$PRFDATGR_FILE" "$PRFDATGR_STNR" "$PRFDATGR_SERIE" "4" "Es handelt sich um eine Sampledatei"
					#entferne Sample Sofort? NACHDENKEN!!
					AddGesamtGeloescht "$PRFDATGR_SIZE"
			fi

		fi

  	else

		echo "keine Video Datei: " $(basename "$PRFDATGR_FILE") >&2

		if [ "$PRFDATGR_STNR" != "ERROR" ]; then # Prüfung ob PruefeDateiGroeßeUndTyp von PruefeDateiFuerStaffel aufgerufen wurde, wenn ja kein Logging und löschen

			file "$PRFDATGR_FILE" | grep -i  -e RAR -e archive -e 7z -e zip >/dev/null

			if [ $? -eq 0 ]; then

				SchreibeInLogdatei "$PRFDATGR_FILE" "$PRFDATGR_STNR" "$PRFDATGR_SERIE" "5" "Es handelt sich um ein Archiv"
				#entferne Datei Sofort? NACHDENKEN!!	
				AddGesamtGeloescht "$PRFDATGR_SIZE"

			else

				SchreibeInLogdatei "$PRFDATGR_FILE" "$PRFDATGR_STNR" "$PRFDATGR_SERIE" "4" "Es handelt sich um keine Videodatei"
				#entferne Datei Sofort? NACHDENKEN!!			
				AddGesamtGeloescht "$PRFDATGR_SIZE"

			fi

			DATGRCHECK=1

		fi
	fi

	echo ">>>>PruefeDateiGroeßeUndTyp<<<< - Return = $DATGRCHECK" >&2

	return $DATGRCHECK

}

#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeDateiTyp
{

	FILE=$1
	RETURN=0

	echo ">>>>PruefeDateiTyp<<<< - Wenn OK return 0 (True)" >&2
	
	file "$FILE" | grep -i -e video -e ebml -e Matroska -e MPEG >/dev/null # Prüfe ob Datei einer der gelisteten Dateitypen ist

	if [ $? -eq 1 ]; then # Wenn Dateityp keiner der zuvor gelisteten Dateitypen ist dann prüfe ob Datei einer der in der dtyplist.txt enthaltenen Dateiendungen hat

		RETURN=1

  		DTYPE=${FILE/*./}
  		grep -i "$DTYPE" ./dtyplist.txt >/dev/null
		  
		if [ $? -eq 0 ]; then

			RETURN=0

		fi

  	fi

	echo ">>>>PruefeDateiTyp<<<< - Return = $RETURN" >&2

	return $RETURN

}


#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function IfAufBlacklistReturnTrue
{

	local FILE=$1
	local RETURN=1

	echo ">>>>IfAufBlacklistReturnTrue<<<< - Wenn auf Blacklist return 0 (True)" >&2

	if [ -e ./blacklist.txt ]; then
		
		DTYPE=${FILE/*./}
		grep -i "$DTYPE" ./blacklist.txt >/dev/null
			
		if [ $? -eq 0 ]; then

			RETURN=0

		fi

	fi

	echo ">>>>IfAufBlacklistReturnTrue<<<< - Return = $RETURN" >&2

	return $RETURN

}


#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeDateiGroeße
{

	local FILE=$1

	local SIZE=$( stat -c %s "$FILE" ) # Eruriere Byteanzahl der aktuellen Datei

	echo "$SIZE"

}

#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function AddGesamtGeloescht
{

	local SIZE=$1

	echo "Datei mit" $SIZE "Bytes wird gelöscht" >&2

	local DELETED=$(sed -n 1p ./delbytes.txt)

	echo $((SIZE + $DELETED)) > ./delbytes.txt

	echo "Status insgesamt gelöscht:" $((SIZE + $DELETED)) "Bytes" >&2 

}


#-----------------------------------------------------------------------------------------
# FUNKTION Prüfe Datei oder Ordner für Folge
#-----------------------------------------------------------------------------------------
function PruefeDateiFuerFolge
{

	echo ">>>>PruefeDateiFuerFolge<<<< - Wenn gültige Datei return 0 (True)" >&2
	local PRUEFDATEI=$1
	local PRUEF_STNR=$2
	local PRUEF_SERIE=$3
	local PRUEF_CHKSTAFFEL=$4
	local DATEICHECK1=1
	local DOPPELFOLGECHECK=1
	local PRUEF_FILE
	local EPNR
	local EPNR2

	if [ -d "$PRUEFDATEI" ]; then # Wenn es sich um einen Ordner handelt dann...

		echo "Datei ist Ordner: " $(basename "$PRUEFDATEI") >&2
		echo "Suche Dateien..." >&2
		
		PRUEF_CHKSTAFFEL=1
		# An dieser stelle könnte man DateiVerschieben und DateiOderOrdnerLoeschen aufrufen. es muss aber darauf geachtet werden, dass es sich um einen Folgenordner handelt und nicht ein Staffelordner

		while read PRUEF_FILE # Suche Dateien im Ordner
		do

			echo "Datei gefunden: " $(basename "$PRUEF_FILE") >&2
			PruefeDateiGroeßeUndTyp "$PRUEF_FILE" "$PRUEF_STNR" "$PRUEF_SERIE"

			if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...
				
				EPNR=$(ExtrahiereFolgennummerAusDatei "$PRUEF_FILE" "$PRUEF_SERIE")
				DATEICHECK1=$?

				if [ $DATEICHECK1 -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

					EPNR=$(ExtrahiereFolgennummerAusOrdner "$PRUEF_FILE" "$PRUEF_SERIE")
					DATEICHECK1=$?

					if [ $DATEICHECK1 -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

						EPNR=$(IfZweiOderDreiStelligReturnTrue "$PRUEF_FILE" "$PRUEF_STNR" "$PRUEF_SERIE")
						DATEICHECK1=$?

					fi
				fi

				if [ $DATEICHECK1 -eq 0 ]; then # Wenn die EP Nummer NOTOK dann...

					# Prüfe ob Doppelfolge
					EPNR2=$(IfDoppelfolgeReturnTrue "$PRUEF_SERIE" "$PRUEF_STNR" "$EPNR" "$PRUEF_FILE" "$PRUEF_CHKSTAFFEL")
					DOPPELFOLGECHECK=$?

				fi

			fi

		done  <<< "$(find "$PRUEFDATEI" -type f)"

	else

		echo "Datei gefunden: " $(basename "$PRUEFDATEI") >&2

		PRUEF_CHKSTAFFEL=0

		PruefeDateiGroeßeUndTyp "$PRUEFDATEI" "$PRUEF_STNR" "$PRUEF_SERIE"

		if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...

			EPNR=$(ExtrahiereFolgennummerAusDatei "$PRUEFDATEI" "$PRUEF_SERIE")
			DATEICHECK1=$?

			#if [ $DATEICHECK1 -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

			#	EPNR=$(ExtrahiereFolgennummerAusOrdner "$PRUEFDATEI" "$PRUEF_SERIE")
			#	DATEICHECK1=$?

				if [ $DATEICHECK1 -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

					EPNR=$(IfZweiOderDreiStelligReturnTrue "$PRUEFDATEI" "$PRUEF_STNR" "$PRUEF_SERIE")
					DATEICHECK1=$?

				fi
			#fi

			if [ $DATEICHECK1 -eq 0 ]; then # Wenn die EP Nummer NOTOK dann...

				# Prüfe ob Doppelfolge
				EPNR2=$(IfDoppelfolgeReturnTrue "$PRUEF_SERIE" "$PRUEF_STNR" "$EPNR" "$PRUEFDATEI" "$PRUEF_CHKSTAFFEL")
				DOPPELFOLGECHECK=$?

			fi
		fi

	fi

	if [ $DOPPELFOLGECHECK -eq 0 ]; then 

		DATEICHECK1=2

	fi



	echo ">>>>PruefeDateiFuerFolge<<<< - Return = $DATEICHECK1" >&2
	echo ">>>>PruefeDateiFuerFolge<<<< - EP Nummer = $EPNR" >&2

	echo "$EPNR"

	return $DATEICHECK1

}


#-----------------------------------------------------------------------------------------
# FUNKTION Staffel Ordner auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function IfStaffelReturnTrue
{

	local CHECK_STAFFEL=$1
	local CHECK_SERIE=$2
	local STCHECK=1

	echo ">>>>IfStaffelReturnTrue<<<< - Wenn Staffelnummer OK return 0 (True)" >&2

	if [ -d "$CHECK_STAFFEL" ]; then # Wenn es sich um keinen Ordner handelt, dann Staffel = False

		# Extrahiere nur die reine Staffel Nummer
		STNR=$(basename "$CHECK_STAFFEL")
		STNR=${STNR//1080p/}
		STNR=${STNR//18p/}
		STNR=${STNR//720p/}
		STNR=${STNR//72p/}
		STNR=${STNR//7p/}
		STNR=${STNR//480p/}
		STNR=${STNR//x264/}
		STNR=${STNR//h264/}
		STNR=${STNR//x265/}
		STNR=${STNR//h265/}
		STNR=$(echo "$STNR" | sed "s/[0-9]\+\-[0-9]\+//")
		STNR=$(echo "$STNR" | grep -E -o -i "[0-9][0-9]{0,2}")

		if [ "$STNR" != "0" ]; then # Wenn Staffelnummer nicht Null ist, dann schneide führende Null aus

			STNR=$(echo $STNR | sed "s/^0*//")

		fi

		COUNT=${#STNR}
		if [ $COUNT -le 2 ] && [ $COUNT -ne 0 ]; then # Wenn weniger oder gleich 2 Digits, dann Staffel OK

			STCHECK=0

		fi

	else

		STCHECK=1

	fi


	# Prüfe ob die Datei oder der Ordner eine Folge ist, wenn Ja > Staffel = False
	if [ $STCHECK -eq 0 ]; then

		ExtrahiereFolgennummerAusDatei "$CHECK_STAFFEL" "$CHECK_SERIE" "1"
		if [ $? -eq 0 ]; then

			STCHECK=1

		else

			# IfZweiOderDreiStelligReturnTrue "$CHECK_STAFFEL" "ERROR" "$CHECK_SERIE"
			# if [ $? -eq 0 ]; then

			# 	STCHECK=1

			# else

			# 	STCHECK=0

			# fi

			STCHECK=0

		fi

	fi

	echo ">>>>IfStaffelReturnTrue<<<< - Return = $STCHECK" >&2
	echo ">>>>IfStaffelReturnTrue<<<< - Staffelnummer = $STNR" >&2

	echo "$STNR"

	return $STCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Prüfe ob Datei bereits Korrekt benannt ist
#-----------------------------------------------------------------------------------------
function IfDateiBereitsRichtigReturnFalse
{

local DATEI1=$1
local DATEI2=$2

echo "Die Datei '$DATEI1' ist ident mit der Datei '$DATEI1' es muss nichts getan werden benannt ist" >&2

return 1

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Taufe
#-----------------------------------------------------------------------------------------
function DateiOderOrdnerUmbenennen
{

local DATEI1=$1
local DATEI2=$2

echo "die $DATEI1 wird umbenannt in $DATEI2" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Wenn kein Staffelordner existiert wird dieser erstellt
#-----------------------------------------------------------------------------------------
function StaffelOrdnerErstellen
{

local PFAD=$1
local STAFFEL=$2

echo "Staffelordner $STAFFEL wird im PFad $PFAD erstellt" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei wird an vorgesehenen Platz verschoben
#-----------------------------------------------------------------------------------------
function DateiVerschieben
{

local DATEI=$1
local PFAD=$2

echo "die $DATEI wird verschoben in $PFAD" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei oder ein Ordner wird gelöscht
#-----------------------------------------------------------------------------------------
function DateiOderOrdnerLoeschen
{

local DATEI=$1

echo "Die Datei oder der Ordner $DATEI wird gelöscht" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - SchreibeInLogdatei
#-----------------------------------------------------------------------------------------
function SchreibeInLogdatei
{

	local LOG_DATEI=$1
	local LOG_STNR=$2
	local LOG_SERIE=$3
	local LOG=$4
	local LOG_STRING=$5

	echo "Datei wird geloggt..." >&2

	case $LOG in

		1) 	echo -n "Fehlecode MM01 | Kein Serienordner | Ursache: $LOG_STRING | " 														>> ./massmove_log_$CreateLogTime.txt	;;
		2)	echo -n "Fehlecode MM02 | Kein Staffelordner oder ähnlches | Ursache: $LOG_STRING | " 										>> ./massmove_log_$CreateLogTime.txt	;;
		3)	echo -n "Fehlecode MM03 | Taufe nicht möglich | Ursache: $LOG_STRING | " 													>> ./massmove_log_$CreateLogTime.txt	;;
		4)	echo -n "Fehlecode MM00 | Datei/Ordner entfernt | Ursache: $LOG_STRING | " 													>> ./massmove_log_$CreateLogTime.txt	;;
		5)	echo -n "Fehlecode MM04 | Archiv Datei | Ursache: $LOG_STRING | " 															>> ./massmove_log_$CreateLogTime.txt	;;
		6)	echo -n "Fehlecode MM05 | Datei musste nicht bearbeitet werden | Ursache: $LOG_STRING | " 									>> ./massmove_log_$CreateLogTime.txt	;;
		7)	echo -n "Fehlecode MM06 | Ordner ist leer | Ursache: $LOG_STRING | " 														>> ./massmove_log_$CreateLogTime.txt	;;
													
	esac
	
	echo "Staffel " "$LOG_STNR" " | " 																									>> ./massmove_log_$CreateLogTime.txt
	echo "Serienname: " $(basename "$LOG_SERIE") " | " 																					>> ./massmove_log_$CreateLogTime.txt
	echo "Datei: " $(basename "$LOG_DATEI") " | " 																						>> ./massmove_log_$CreateLogTime.txt
	echo -e "Pfad: " "$LOG_DATEI" "\r\n"																								>> ./massmove_log_$CreateLogTime.txt
	#echo -e "-------------------------------------------------------------------------------------------------------------------\r\n" 	>> ./massmove_log_$CreateLogTime.txt

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Schreibe Taufungsprotokoll
#-----------------------------------------------------------------------------------------
function ProtokolliereTaufe
{
	local PROTO=$1
	local PROTO_DATEIURSPRUNG=$2
	local PROTO_DATEIZIEL=$3
	local PROTO_STRING=$4

	echo "Taufe wird Protokolliert..." >&2

	case $PROTO in

		1) 	echo -n -e "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< $PROTO_STRING >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\r\n"	>> ./massmove_umbenannt_$CreateLogTime.txt	;;
		2)	echo -n -e "Neuer Dateiname: $PROTO_STRING | Ursprungsname: $(basename "$PROTO_DATEIURSPRUNG") | Pfad: $PROTO_DATEIZIEL\r\n"					>> ./massmove_umbenannt_$CreateLogTime.txt	;;
		3)	echo -n -e "Folge wurde kopiert | Ursprungspfad: $PROTO_DATEIURSPRUNG | Neuerpfad $PROTO_DATEIZIEL\r\n" 										>> ./massmove_umbenannt_$CreateLogTime.txt	;;
		4)	echo -n -e "Staffelordner wurde erstellt | Ursprungspfad: $PROTO_DATEIURSPRUNG | Neuerpfad $PROTO_DATEIZIEL\r\n" 								>> ./massmove_umbenannt_$CreateLogTime.txt	;;												
	esac

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei oder ein Ordner wird gelöscht
#-----------------------------------------------------------------------------------------
function IfExtraContentReturnTrue
{

	local CONT_DATEI=$1
	local CONT_SERIE=$2
	local EXTRASCHECK=1
	
	echo ">>>>IfExtraContentReturnTrue<<<< - Wenn es Extracontent ist return 0 (True)" >&2

	echo "$CONT_DATEI" | grep -i -e Film -e movie -e spe[cz]ial -e extra >/dev/null # Suche nach aufgelisteten Wörtern und gebe >=1 (Error) oder 0 (Success) zurück

	if [ $? -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

	EXTRASCHECK=1

	else

	EXTRASCHECK=0

	fi

	# Prüfe ob die Datei oder der Ordner eine gültige Folge ist, wenn Ja > Content = False
	if [ $EXTRASCHECK -eq 0 ]; then

		ExtrahiereFolgennummerAusDatei "$CONT_DATEI" "$CONT_SERIE" "1"
		if [ $? -eq 0 ]; then

			EXTRASCHECK=1

		else

			EXTRASCHECK=0

			echo "Es handelt sich bei $( basename "$CONT_DATEI" ) um keine Serie bzw. Spezialcontent" >&2
			SchreibeInLogdatei "$CONT_DATEI" "nichts" "$CONT_SERIE" "2" "Enthält im Namen film/movie, spe[cz]ial oder extra"

		fi

	fi



	echo ">>>>IfExtraContentReturnTrue<<<< - Return = $EXTRASCHECK" >&2

	return $EXTRASCHECK

}


#-----------------------------------------------------------------------------------------
# INNERSTE SCHLEIFE - FOLGEN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function InnersteSchleife_Folgen
{

	local STAFFEL_1=$1
	local STNR_1=$2
	local SERIE_1=$3
	local CHECKSTAFFEL_1
	local FOLGE
	local EPNR
	local CHECKFOLGEOK

	for FOLGE in "$STAFFEL_1"/*; do # FOLGEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

		if [ -a "$FOLGE" ]; then
		
			echo "Loop 3 - Datei:" $(basename "$FOLGE")  >&2

			let EPCOUNT=EPCOUNT+1 # Zähler für Endprotokoll

			EPNR=$(PruefeDateiFuerFolge "$FOLGE" "$STNR_1" "$SERIE_1" "$CHECKSTAFFEL_1")
			CHECKFOLGEOK=$?

			case $CHECKFOLGEOK in

				0) 	printout "$SERIE_1" "$STNR_1" "$EPNR" "$FOLGE" "1" ;;
				1) 	echo "Es Konnte keine Folgennummer extrahiert werden." >&2 ;;
				2) 	printout "$SERIE_1" "$STNR_1" "$EPNR" "$FOLGE" "0" ;;
														
			esac

		else

			echo "ERROR: Der Staffelordner enthält keine Dateien oder Ordner" >&2
			SchreibeInLogdatei "$FOLGE" "-" "$SERIE_1" "7" "Der Staffelordner enthält keine Dateien oder Ordner"

		fi

	done
}


#-----------------------------------------------------------------------------------------
# MITTLERE SCHLEIFE - STAFFELN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function MittlereSchleife_Staffeln
{

	local SERIE_1=$1
	local STAFFEL
	local EPNR
	local STNR
	local CHECKSTAFFEL=1
	local CHECKXCONTENT=1
	local CHECKFOLGEOK=1
	local OLDSTNR=0
	declare -a STAFFELARRAY=()
	local ZAEHLER=0

	STAFFELARRAY+=("0")
	for STAFFEL in "$SERIE_1"/*; do # STAFFELN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

		if [ -a "$STAFFEL" ]; then

			echo "Loop 2 - Datei:" $(basename "$STAFFEL")  >&2

			STNR=$(IfStaffelReturnTrue "$STAFFEL" "$SERIE_1")
			CHECKSTAFFEL=$?
			if [ $CHECKSTAFFEL -eq 1 ]; then # Wenn letzter Rückgabe Wert 0 (Success) dann...
				IfExtraContentReturnTrue "$STAFFEL" "$SERIE_1"
				CHECKXCONTENT=$?
			fi

			if [ $CHECKSTAFFEL -eq 0 ]; then # Wenn letzter Rückgabe Wert 0 (Success) dann...

				let SEASONCOUNT=SEASONCOUNT+1  # Zähler für Endprotokoll

				InnersteSchleife_Folgen "$STAFFEL" "$STNR" "$SERIE_1" "$CHECKSTAFFEL"

			else

				if [ $CHECKXCONTENT -eq 1 ]; then
					echo "Kein Staffelordner: " $(basename "$STAFFEL") " - WARNING"  >&2
					echo "Prüfe ob gültige Folge..."  >&2
					echo "Extrahiere Staffelnummer aus Datei..."  >&2
					echo "Erstellen von Staffelordnern notwendig"  >&2

					STNR=$(PruefeDateiFuerStaffel "$STAFFEL" "$SERIE_1")
					CHECKSTAFFEL=$?
					EPNR=$(PruefeDateiFuerFolge "$STAFFEL" "$STNR" "$SERIE_1" "$CHECKSTAFFEL")
					CHECKFOLGEOK=$?

					if [ $CHECKSTAFFEL -eq 0 ]; then
						case $CHECKFOLGEOK in

							0) 	printout "$SERIE_1" "$STNR" "$EPNR" "$STAFFEL" "1" ;;
							1) 	echo "Es Konnte keine Folgennummer extrahiert werden." >&2 ;;
							2) 	printout "$SERIE_1" "$STNR" "$EPNR" "$STAFFEL" "0" ;;
																	
						esac

					else
						if [ $CHECKFOLGEOK -eq 0 ] || [ $CHECKFOLGEOK -eq 2 ]; then
						
							SchreibeInLogdatei "$STAFFEL" "$STNR" "$SERIE_1" "3" "Staffelnummer konnte nicht extrahiert werden"

						fi
					fi

					# Staffelordner erstellen
					# Datei nehmen und in Staffelordner verschieben
					# loop neustarten

					if [ "$OLDSTNR" != "$STNR" ]; then
						echo ">>111>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> OLD $OLDSTNR >>>>>> NEW $STNR >>>>>> COUNT $SEASONCOUNT" >&2
						OLDSTNR=$STNR
						echo ">>222>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> OLD $OLDSTNR >>>>>> NEW $STNR >>>>>> COUNT $SEASONCOUNT" >&2
						ZAEHLER=0
						for i in $STAFFELARRAY; do

							if [[ $i -ne $STNR ]]; then

								let ZAEHLER=ZAEHLER+1

								STAFFELARRAY+=("$STNR")

								echo ">>333>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ZÄHLER" $ZAEHLER ">>>>>> I" ${STAFFELARRAY[@]} ">>>>>> COUNT" $SEASONCOUNT >&2

							else

								let ZAEHLER=0

							fi

						done

					
						if [ $ZAEHLER -ge 1 ]; then

							let SEASONCOUNT=SEASONCOUNT+1  # Zähler für Endprotokoll
							echo ">>444>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ZÄHLER $ZAEHLER >>>>>> STNR $STNR >>>>>> COUNT $SEASONCOUNT" >&2

						fi

					fi

					if [ $CHECKFOLGEOK -eq 0 ] || [ $CHECKFOLGEOK -eq 2 ]; then

						let EPCOUNT=EPCOUNT+1  # Zähler für Endprotokoll

					fi

				fi

			fi

		else

			echo "ERROR: Der Serienordner enthält keinen Staffelordner" >&2
			SchreibeInLogdatei "$STAFFEL" "-" "$SERIE_1" "7" "Der Serienordner enthält keinen Staffelordner"

		fi

	done

}


#-----------------------------------------------------------------------------------------
# OBERSTE SCHLEIFE - SERIEN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function ObersteSchleife_Serien
{

local SERIE
local CHECKBLACKLIST
local CHECKXCONTENT

for SERIE in $SEARCHPATH; do # SERIEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

echo "Loop 1 - Datei:" $(basename "$SERIE")  >&2

	if [ -d "$SERIE" ]; then # Wenn File existiert und ein Verzeichnis ist dann gehe weiter 

		let SERIECOUNT=SERIECOUNT+1 # Zähler für Endprotokoll

		echo "------------------------------------" $( basename "$SERIE" ) "------------------------------------" >&2

			IfAufBlacklistReturnTrue "$( basename "$SERIE" )"
			CHECKBLACKLIST=$?
			IfExtraContentReturnTrue "$SERIE" "$SERIE"
			CHECKXCONTENT=$?

			if [ $CHECKBLACKLIST -eq 1 ] && [ $CHECKXCONTENT -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

				ProtokolliereTaufe "1" "$SEARCHPATH" "$SEARCHPATH" "$( basename "$SERIE" )"

				MittlereSchleife_Staffeln "$SERIE"

			else

				echo "Serie '$( basename "$SERIE" )' ist auf der Ausnahmeliste Überspringe diese Serie" >&2

			fi	

	else

		echo "ERROR: Syntaxfehler,kein korrekter Pfad angegeben oder keine Serienordner vorhanden" >&2
		SchreibeInLogdatei "$SERIE" "-" "-" "7" "Syntaxfehler,kein korrekter Pfad angegeben oder keine Serienordner vorhanden"

	fi

done

}


#-----------------------------------------------------------------------------------------
# Prüfe auf absolute Pfade (Slashes am Anfang und am Ende), Wenn keine Vorhanden füge welche hinzu
#-----------------------------------------------------------------------------------------
function PruefeObSlashVorhanden
{

SEARCHPATH="$1"

echo "$SEARCHPATH" | grep -E ^/ >/dev/null
if [ $? -eq 1 ]; then

	SEARCHPATH="/$SEARCHPATH"

fi

echo "$SEARCHPATH" | grep -E /\$ >/dev/null
if [ $? -eq 1 ]; then

	SEARCHPATH="$SEARCHPATH/"

fi

	echo "$SEARCHPATH" # sozusagen ein return 

}


#-----------------------------------------------------------------------------------------
# EINSTIEGSPUNKT - Eroierung des Pfades und der Opionen#
#-----------------------------------------------------------------------------------------
function Einstieg
{

if [ -z "$2" ]; then # Wenn der String ($2 = 2. Aufrufparameter) leer ist dann setze Pfad wo Skript liegt.

    SEARCHPATH="."

else

   	SEARCHPATH="$2"

fi

if [ -n "$1" ]; then # Wenn der String ($1 = 1. Aufrufparameter) nicht leer ist dann..

	if [ "$1" == "--help" ]; then # Wenn der String "--help" ist dann..

		cat massmove_man.txt
		exit

	else

		if [ -n "$2" ]; then # Wenn der String nicht leer ist dann ist der Aufrufparameter 1 für den Pfad Zuständig

			SEARCHPATH=$(PruefeObSlashVorhanden "$2")
			SEARCHPATH="$SEARCHPATH""$1"

		else

			SEARCHPATH=$(PruefeObSlashVorhanden "$1")

		fi

	fi	

fi

# # Entscheidung - Testmodus oder Echtmodus?
# if [ "$1" = "-notest" ] || [ "$2" = "-notest" ] || [ "$3" = "-notest" ] || [ "$4" = "-notest" ] || [ "$5" = "-notest" ]; then # Wenn der einer der Aufrufparameter -notest enthält führe Programm im Echtmodus aus

#     TESTMODUS=0

# fi

# # Entscheidung - Testmodus oder Echtmodus?
# if [ "$1" = "-delonly" ] || [ "$2" = "-delonly" ] || [ "$3" = "-delonly" ] || [ "$4" = "-delonly" ] || [ "$5" = "-delonly" ]; then # Wenn der einer der Aufrufparameter -notest enthält führe Programm im Echtmodus aus

#     DELONLY=0

# fi
ObersteSchleife_Serien # Los gehts
}


#-----------------------------------------------------------------------------------------
# EINSTIEGSPUNKT - Eroierung des Pfades und der Opionen
#-----------------------------------------------------------------------------------------

# Input Usage   ./massmove.sh -notest -s "Akte X" -p /Media/Serien/
#	

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"

	case $key in
		-p|--searchpath)
		SEARCHPATH="$2"
		shift # past argument
		shift # past value
		;;
		-s|--string)
		SEARCHCHAR="$2"
		shift # past argument
		shift # past value
		;;
		-notest)
		NOTEST="$2"
		shift # past argument
		;;
		--help)
		HELP=0
		shift # past argument
		;;
		--default)
		DEFAULT=YES
		shift # past argument
		;;
		*)    # unknown option
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
	esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

echo NOTEST			= "${NOTEST}"
echo SEARCHPATH		= "${SEARCHPATH}"
echo SEARCHCHAR		= "${SEARCHCHAR}"
echo HELP			= "${HELP}"
echo DEFAULT        = "${DEFAULT}"

if [[ -n $1 ]]; then

    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"

fi

if [[ -n $SEARCHCHAR ]]; then

	SEARCHPATH="$SEARCHPATH""$SEARCHCHAR"
	echo "1 " "$SEARCHPATH" >&2

	if [[ -d $SEARCHPATH ]]; then

		SEARCHPATH="$SEARCHPATH"
		echo "2 " "$SEARCHPATH" >&2

	else

		SEARCHPATH="$SEARCHPATH*"
		echo "3 " "$SEARCHPATH" >&2
	fi

else

	 SEARCHPATH="$SEARCHPATH*"
	echo "4 " "$SEARCHPATH" >&2

fi

ObersteSchleife_Serien

#Einstieg

#-----------------------------------------------------------------------------------------
# AUSSTIEGSPUNKT
#-----------------------------------------------------------------------------------------
	after=$(date +%s)
	
	echo "-----------------------------------------------------"
	echo -n "Erfolgreich bearbetet | "
	echo "elapsed time:" $((after - $before)) "seconds"
	echo "bearbeitete Serien:" "$SERIECOUNT"
	echo "bearbeitete Staffeln:" "$SEASONCOUNT"
	echo "bearbeitete Folgen:" "$EPCOUNT"
	echo "gesamt Größe gelöschter Objekte:" $(sed -n 1p ./delbytes.txt) "Bytes"

	echo -e "----------------------------------------------------------------\r\n" 			>> ./massmove_log_$CreateLogTime.txt
	echo -n "Erfolgreich bearbetet | "														>> ./massmove_log_$CreateLogTime.txt
	echo -e "elapsed time:" $((after - $before)) "seconds\r\n"								>> ./massmove_log_$CreateLogTime.txt
	echo -e "bearbeitete Serien:" "$SERIECOUNT\r\n"											>> ./massmove_log_$CreateLogTime.txt
	echo -e "bearbeitete Staffeln:" "$SEASONCOUNT\r\n"										>> ./massmove_log_$CreateLogTime.txt
	echo -e "bearbeitete Folgen:" "$EPCOUNT\r\n"											>> ./massmove_log_$CreateLogTime.txt
	echo "gesamt Größe gelöschter Objekte:" $(sed -n 1p ./delbytes.txt) "Bytes"				>> ./massmove_log_$CreateLogTime.txt

#-----------------------------------------------------------------------------------------
