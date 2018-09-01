#!/bin/bash
#/media/5f131047-b830-4d89-88f3-f139bebfdef6/DataHub/Projektmappen/Visual_Studio/Projects/massmove

export before=$(date +%s)
export CreateLogTime=$(date +%d.%m.%Y@%H-%M-%S)
export DELETEGLOBAL=0
export SERIECOUNT=0
export SEASONCOUNT=0
export EPCOUNT=0
export TESTMODUS=1
export SEARCHPATH=""

#entferne Logdatei wenn vorhanden
#rm -f massmove_log.txt
# lege logdatei mit aktuellem Zeitstempel an
echo -e "Start der Protokollierung: $CreateLogTime\r\n" > massmove_log_$CreateLogTime.txt

# lege ausgelagerten bytezähler an
echo "0" > delbytes.txt

#-----------------------------------------------------------------------------------------
# FUNKTION - Hilfsfunktion um mehr als ein return eienr methode zu erhalten
#-----------------------------------------------------------------------------------------
function GetMultipleReturn
{

    echo `echo $1 | cut -d',' -f $2`

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
	local PRNTCHECK=1
	
	echo ">>>>Printout<<<< - Wenn erfolg return 0 (True)" >&2

	local PRINTOUT_EXTFOLGE=$(EntferneUnnötigeStringTeile "$PRINTOUT_DATEI" "$PRINTOUT_SERIE")

	EPNR=$(echo $EPNR | sed "s/^0*//")
	let local EPNR2=EPNR+1

	echo "eins: " $EPNR >&2
	echo "zwei: " $EPNR2 >&2
	echo "EXTFOLGE" "$PRINTOUT_EXTFOLGE" >&2

	#Prüfe ob dobbelfolge oder nicht
	local STRING=${#EPNR}

	if [ "$STRING" -eq 3 ]; then

		echo "dreistellig" >&2
		echo "$PRINTOUT_EXTFOLGE" | grep -E -i "$EPNR2"
		local EPCHK=$?		

		local STCHK=$(echo $EPNR | cut -b 1)
		echo "$STCHK" >&2
		echo "$PRINTOUT_STNR" >&2

		if [ "$PRINTOUT_STNR" == "$STCHK" ]; then

			EPNR2=${EPNR2:1}
			EPNR=${EPNR:1}

		fi

			EPNR=$( echo $EPNR | sed "s/^0*//" )
			EPNR2=$( echo $EPNR2 | sed "s/^0*//" )

	else

		echo "zweistellig mit E" >&2
		echo "$PRINTOUT_EXTFOLGE" | grep -E -i "([efx\-]|ep\.?)$EPNR2"
		EPCHK=$?

	fi

	if [ $EPCHK -eq 0 ]; then

		echo "*********************************************" >&2

		if [ -z $PRINTOUT_STNR ]; then

			printf "%s - E%02dE%02d\n" "$(basename "$PRINTOUT_SERIE")" "$EPNR" "$EPNR2"
			PRNTCHECK=0

		else

			printf "%s - S%02dE%02dE%02d\n" "$(basename "$PRINTOUT_SERIE")" "$PRINTOUT_STNR" "$EPNR" "$EPNR2"
			PRNTCHECK=0

		fi

		echo "*********************************************" >&2

	else

		echo "*********************************************" >&2
		if [ -z $PRINTOUT_STNR ]; then

			printf "%s - E%02d\n" "$(basename "$PRINTOUT_SERIE")" "$EPNR"
			PRNTCHECK=0

		else

			printf "%s - S%02dE%02d\n" "$(basename "$PRINTOUT_SERIE")" "$PRINTOUT_STNR" "$EPNR"
			PRNTCHECK=0

		fi

		echo "*********************************************" >&2

	fi

	echo ">>>>Printout<<<< - Return = $PRNTCHECK" >&2
	echo ">>>>Printout<<<< - EP Nummer = $EPNR" >&2

	return $PRNTCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - EPNR säubern
#-----------------------------------------------------------------------------------------
function ExtrahiereFolgennummer
{

	local EXTRAKT_DATEI=$1
	local EXTRAKT_STNR=$2
	local EXTRAKT_SERIE=$3
	local EPNRCHECK=1
	
	echo ">>>>ExtrahiereFolgennummer<<<< - Wenn gültige Nummer return 0 (True)" >&2

	# prüfe ob Dateiname richtig 

		# if [ $STNR_1 -ne 1 -a "$FOLGE_1" -ne 8 ]; then
		# EXTFOLGE=${EXTFOLGE//108p/}
		# fi

	local EPNR=$(EntferneUnnötigeStringTeile "$EXTRAKT_DATEI" "$EXTRAKT_SERIE")
	
	EPNR=$(echo "$EPNR" | grep -E -o -i "([efx]|ep\.?)[0-9]*" | grep -E -o "[0-9][0-9]{0,2}")
	local FRES=$?

	EPNR=$(echo $EPNR | sed q )
	EPNR=$(echo $EPNR | sed "s/^0*//") # Entferne führende Null

	COUNT=${#EPNR}
	echo "COUNT = $COUNT" >&2
	if [ $COUNT -gt 2 ]; then
		NUMBERINSERIE=$(basename "$EXTRAKT_SERIE")
		NUMBERINSERIE=${NUMBERINSERIE//[!0-9]/}

		echo "NUMBERINSERIE = $NUMBERINSERIE" >&2

		EPNR=$(echo $EPNR | sed "s/^$NUMBERINSERIE*//")

		echo "EPNR = $EPNR" >&2

	fi

	if [ $FRES -eq 1 ]; then

		# prüfe ob ordnername eine EP nummer enthält
		local 	DIRSTRING=$( dirname "$EXTRAKT_DATEI" )
				DIRSTRING=$( basename "$DIRSTRING" )
		
		EPNR=$(echo "$DIRSTRING" | grep -E -o -i "([efx]|ep\.?)[0-9]*" | grep -E -o "[0-9][0-9]{0,2}")
		local ORES=$?

		EPNR=$(echo $EPNR | sed q )
		EPNR=$(echo $EPNR | sed "s/^0*//")

		COUNT=${#EPNR}
		if [ $COUNT -gt 2 ]; then
			NUMBERINSERIE=$(basename "$EXTRAKT_SERIE")
			NUMBERINSERIE=${NUMBERINSERIE//[!0-9]/}

			echo "NUMBERINSERIE = $NUMBERINSERIE" >&2

			EPNR=$(echo $EPNR | sed "s/^$NUMBERINSERIE*//")

			echo "EPNR = $EPNR" >&2

		fi

		if [ $ORES -eq 1 ]; then

			EPNRCHECK=1

		else

			EPNRCHECK=0

		fi

	else

		EPNRCHECK=0

	fi

	echo ">>>>ExtrahiereFolgennummer<<<< - Return = $EPNRCHECK" >&2

	echo "$EPNR"

	return $EPNRCHECK

}



#-----------------------------------------------------------------------------------------
# FUNKTION - Episode herausfinden
#-----------------------------------------------------------------------------------------
function EntferneUnnötigeStringTeile
{

	local EXTFOLGE=$(basename "$1")
	local SERIENNAME=$(basename "$2")

	echo ">>>>EntferneUnnötigeStringTeile<<<<" >&2

	# Ersetze in String EXTFOLGE den String recht von "//" mit den string rechts von "/" (empty)
	EXTFOLGE=${EXTFOLGE//1080p/}
	EXTFOLGE=${EXTFOLGE//18p/}
	EXTFOLGE=${EXTFOLGE//720p/}
	EXTFOLGE=${EXTFOLGE//72p/}
	EXTFOLGE=${EXTFOLGE//7p/}
	EXTFOLGE=${EXTFOLGE//480p/}
		# EXTFOLGE=${EXTFOLGE//51/}
		# echo "$EXTFOLGE" | sed "/([efx]|ep\.?)[0-9]?51/!s/51//"
	EXTFOLGE=${EXTFOLGE//x264/}
	EXTFOLGE=${EXTFOLGE//h264/}
	EXTFOLGE=${EXTFOLGE//x265/}
	EXTFOLGE=${EXTFOLGE//h265/}
	EXTFOLGE=${EXTFOLGE#$SERIENNAME}

	echo ">>>>EntferneUnnötigeStringTeile<<<< - Ergebnis = $EXTFOLGE" >&2

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
	
  	echo ">>>>IfZweiOderDreiStelligReturnTrue<<<< - Wenn gültige 2 oder 3 stellige Nummer return 0 (True)" >&2

		local EPNR=$(EntferneUnnötigeStringTeile "$EXTRAKT_DATEI" "$ZWEIDREI_SERIE")

		# EPNR=$(basename "$ZWEIDREI_EXTFOLGE" | sed "s/[^0-9]//g" | cut -d " " -f 2 )
		local EPNR=$(basename "$EPNR" | grep -E -o -i "[0-9][0-9]{0,2}" | sed q)
		if [[ $EPNR =~ ^[0-9]{1,2}$ ]]; then # Wenn zweistellige Nummer, dann...

			EPNR=$( echo $EPNR | sed "s/^0*//" )

			#printout "$ZWEIDREI_SERIE" "$ZWEIDREI_STNR" "$EPNR" "$ZWEIDREI_DATEI"

			ZWEIDREICHECK=0

		else

			if [[ $EPNR =~ ^[0-9]{1,3}$ ]]; then # Wenn dreistellige Nummer, dann...

				# EPNR=${EPNR:1}
				# EPNR=$( echo $EPNR | sed "s/^0*//" )

				#printout "$ZWEIDREI_SERIE" "$ZWEIDREI_STNR" "$EPNR" "$ZWEIDREI_DATEI"

				ZWEIDREICHECK=0

			else

				SchreibeInLogdatei "$ZWEIDREI_DATEI" "$ZWEIDREI_STNR" "$ZWEIDREI_SERIE" "3" "Folgennummer konnte nicht extrahiert werden"

				ZWEIDREICHECK=1

			fi

		fi

		echo ">>>>IfZweiOderDreiStelligReturnTrue<<<< - EP Nummer = $EPNR" >&2

		echo "$EPNR"

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

	echo ">>>>PruefeDateiGroeßeUndTyp<<<< - Wenn Videodatei OK return 0 (True)" >&2


	PruefeDateiTyp "$PRFDATGR_FILE" # Wenn OK return 0 (True)

	if [ $? -eq 0 ]; then # Wenn der geforderte Dateityp enthalten ist überprüfe die Dateigröße

	#prüfe ob datei kein Sample ist (größe der Datei)

		if [ $PRFDATGR_SIZE -gt 20000000 ]; then # Wenn datei über 20MB groß ist dann...

			echo "Videodatei: " $(basename "$PRFDATGR_FILE") >&2
			DATGRCHECK=0

		else

			echo "Sample: " $(basename "$PRFDATGR_FILE") >&2
			DATGRCHECK=1

			SchreibeInLogdatei "$PRFDATGR_FILE" "$PRFDATGR_STNR" "$PRFDATGR_SERIE" "4" "Es handelt sich um eine Sampledatei"
			#entferne Sample Sofort? NACHDENKEN!!
			AddGesamtGeloescht "$PRFDATGR_SIZE"

		fi

  	else

		echo "keine Video Datei: " $(basename "$PRFDATGR_FILE") >&2
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
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeDatei
{
	echo ">>>>PruefeDatei<<<<" >&2
	local PRUEFDATEI=$1
	local PRUEF_STNR=$2
	local PRUEF_SERIE=$3
	
	if [ -d "$PRUEFDATEI" ]; then # Wenn es sich um einen Ordner handelt dann...

		echo "Datei ist Ordner: " $(basename "$PRUEFDATEI") >&2
		echo "Suche Dateien..." >&2
		
		# An dieser stelle könnte man DateiVerschieben und DateiOderOrdnerLoeschen aufrufen. es muss aber darauf geachtet werden, dass es sich um einen Folgenordner handelt und nicht ein Staffelordner

		find "$PRUEFDATEI" -type f | while read PRUEF_FILE # Suche Dateien im Ordner
		do

			echo "Datei gefunden: " $(basename "$PRUEF_FILE") >&2
			PruefeDateiGroeßeUndTyp "$PRUEF_FILE" "$PRUEF_STNR" "$PRUEF_SERIE"

			if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...

				local EPNR=$(ExtrahiereFolgennummer "$PRUEF_FILE" "$PRUEF_STNR" "$PRUEF_SERIE")
							
				if [ $? -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

					EPNR=$(IfZweiOderDreiStelligReturnTrue "$PRUEFDATEI" "$PRUEF_STNR" "$PRUEF_SERIE")
					DATEICHECK=$?

				else

					DATEICHECK=0

				fi

			fi

		done

	else

		echo "Folge ist kein Ordner: " $(basename "$PRUEFDATEI") >&2
		PruefeDateiGroeßeUndTyp "$PRUEFDATEI" "$PRUEF_STNR" "$PRUEF_SERIE"

		if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...

			local EPNR=$(ExtrahiereFolgennummer "$PRUEFDATEI" "$PRUEF_STNR" "$PRUEF_SERIE")
							
				if [ $? -eq 1 ]; then # Wenn die EP Nummer NOTOK dann...

					EPNR=$(IfZweiOderDreiStelligReturnTrue "$PRUEFDATEI" "$PRUEF_STNR" "$PRUEF_SERIE")
					DATEICHECK=$?

				else

					DATEICHECK=0

				fi

		fi

	fi

	echo "$EPNR"

	return $DATEICHECK

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

	if [ -d "$CHECK_STAFFEL" ]; then # Wenn es sich um einen Ordner handelt dann...

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
		STNR=$(echo $STNR | sed "s/^0*//")
		# Zusatz check einbauen ob eine episodennummer vorhanden ist. wenn Ja > Staffel = False

		if [[ $STNR =~ ^[0-9]{1,2}$ ]]; then

			STCHECK=0

		else

			STCHECK=1

		fi

	else

		STCHECK=1

	fi
	
	ExtrahiereFolgennummer "$CHECK_STAFFEL" "$STNR" "$CHECK_SERIE"
	if [ $? -eq 0 ]; then

		STCHECK=1
		echo "STCHECK = $STCHECK" >&2
	else

		STCHECK=0
		echo "STCHECK = $STCHECK" >&2
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
													
	esac
	
	echo "Staffel " "$LOG_STNR" " | " 																									>> ./massmove_log_$CreateLogTime.txt
	echo "Serienname: " $(basename "$LOG_SERIE") " | " 																					>> ./massmove_log_$CreateLogTime.txt
	echo "Datei: " $(basename "$LOG_DATEI") " | " 																						>> ./massmove_log_$CreateLogTime.txt
	echo -e "Pfad: " "$LOG_DATEI" "\r\n"																								>> ./massmove_log_$CreateLogTime.txt
	echo -e "-------------------------------------------------------------------------------------------------------------------\r\n" 	>> ./massmove_log_$CreateLogTime.txt

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

		echo "Es handelt sich bei $( basename "$CONT_DATEI" ) um keine Serie bzw. Spezialcontent" >&2
		SchreibeInLogdatei "$CONT_SERIE" "nichts" "$CONT_DATEI" "2" "Enthält im Namen film/movie, spe[cz]ial oder extra"

	EXTRASCHECK=0

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
local FOLGE 

	for FOLGE in "$STAFFEL_1"/*; do # FOLGEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

echo "Loop 3 - Datei:" $(basename "$FOLGE")  >&2

		let EPCOUNT=EPCOUNT+1 # Zähler für Endprotokoll

		local EPNR=$(PruefeDatei "$FOLGE" "$STNR_1" "$SERIE_1")
		printout "$SERIE_1" "$STNR_1" "$EPNR" "$FOLGE"

	done
}


#-----------------------------------------------------------------------------------------
# MITTLERE SCHLEIFE - STAFFELN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function MittlereSchleife_Staffeln
{

local SERIE_1=$1
local STAFFEL

for STAFFEL in "$SERIE_1"/*; do # STAFFELN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

	echo "Loop 2 - Datei:" $(basename "$STAFFEL")  >&2

	let SEASONCOUNT=SEASONCOUNT+1  # Zähler für Endprotokoll

	STNR=$(IfStaffelReturnTrue "$STAFFEL" "$SERIE_1")
	CHECKSTAFFEL=$?
	IfExtraContentReturnTrue "$STAFFEL" "$SERIE_1"
	CHECKXCONTENT=$?

	if [ $CHECKSTAFFEL -eq 0 ] && [ $CHECKXCONTENT -eq 1 ]; then # Wenn letzter Rückgabe Wert 0 (Success) dann...

		InnersteSchleife_Folgen "$STAFFEL" "$STNR" "$SERIE_1"

	else

		echo "Kein Staffelordner: " $(basename "$STAFFEL") " - WARNING"  >&2
		echo "$STNR"  >&2
		echo "Prüfe ob gültige Folge..."  >&2
		echo "Extrahiere Staffelnummer aus Datei..."  >&2
		echo "Erstellen von Staffelordnern notwendig"  >&2

		local EPNR=$(PruefeDatei "$STAFFEL" "$STNR" "$SERIE_1")
		printout "$SERIE_1" "$STNR" "$EPNR" "$STAFFEL"
		# Staffelordner erstellen
		# Datei nehmen und in Staffelordner verschieben
		# loop neustarten


	fi

done

}


#-----------------------------------------------------------------------------------------
# OBERSTE SCHLEIFE - SERIEN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function ObersteSchleife_Serien
{

local SERIE

for SERIE in $SEARCHPATH*; do # SERIEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

echo "Loop 1 - Datei:" $(basename "$SERIE")  >&2

	if [ -d "$SERIE" ]; then # Wenn File existiert und ein Verzeichnis ist dann gehe weiter 

		let SERIECOUNT=SERIECOUNT+1 # Zähler für Endprotokoll

		echo "------------------------------------" $( basename "$SERIE" ) "------------------------------------" >&2

			IfAufBlacklistReturnTrue "$( basename "$SERIE" )"
			CHECKSTAFFEL=$?
			IfExtraContentReturnTrue "$SERIE" "$SERIE"
			CHECKXCONTENT=$?

			if [ $CHECKSTAFFEL -eq 1 ] && [ $CHECKXCONTENT -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

			MittlereSchleife_Staffeln "$SERIE"

			else

			echo "Serie '$( basename "$SERIE" )' ist auf der Ausnahmeliste Überspringe diese Serie" >&2

			fi	

	else

		echo "ERROR: Syntaxfehler,kein korrekter Pfad angegeben oder keine Serienordner vorhanden" >&2

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

# Entscheidung - Testmodus oder Echtmodus?
if [ "$1" = "-notest" ] || [ "$2" = "-notest" ] ||  [ "$3" = "-notest" ]; then # Wenn der einer der Aufrufparameter -notest enthält führe Programm im Echtmodus aus

    TESTMODUS=0

fi

ObersteSchleife_Serien # Los gehts

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

	echo "----------------------------------------------------------------\r\n" 			>> ./massmove_log_$CreateLogTime.txt
	echo -n "Erfolgreich bearbetet | "														>> ./massmove_log_$CreateLogTime.txt
	echo -e "elapsed time:" $((after - $before)) "seconds\r\n"								>> ./massmove_log_$CreateLogTime.txt
	echo -e "bearbeitete Serien:" "$SERIECOUNT\r\n"											>> ./massmove_log_$CreateLogTime.txt
	echo -e "bearbeitete Staffeln:" "$SEASONCOUNT\r\n"										>> ./massmove_log_$CreateLogTime.txt
	echo -e "bearbeitete Folgen:" "$EPCOUNT\r\n"											>> ./massmove_log_$CreateLogTime.txt
	echo "gesamt Größe gelöschter Objekte:" $(sed -n 1p ./delbytes.txt) "Bytes"				>> ./massmove_log_$CreateLogTime.txt

#-----------------------------------------------------------------------------------------
