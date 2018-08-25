#!/bin/bash
before=$(date +%s)
export DELETEGLOBAL=0
export TESTMODUS=1
rm ./massmove_log.txt

#-----------------------------------------------------------------------------------------
# FUNKTION - printout
#-----------------------------------------------------------------------------------------
function printout
{

	SERIE_2=$1
	STNR_2=$2
	EPNR=$3
	EXTFOLGE=$4
	PCHECK=1
	
	echo ">>>>Printout<<<<"
	echo "$EPNR"
	EPNR=$(echo $EPNR | sed "s/^0*//")
	let EPNR2=EPNR+1
	echo "eins: " $EPNR
	echo "zwei: " $EPNR2
	echo "$EXTFOLGE"

#Prüfe ob dobbelfolge oder nicht
	STRING=${#EPNR}

	if [ "$STRING" -eq 3 ]; then

		echo "dreistellig"
		echo "$EXTFOLGE" | grep -E -i "$EPNR2"
		EPCHK=$?		
		STCHK=$(echo $EPNR | cut -b 1)
		echo "$STCHK"
		echo "$STNR_2"

		if [ "$STNR_2" == "$STCHK" ]; then

			EPNR2=${EPNR2:1}
			EPNR=${EPNR:1}

		fi

			EPNR=$( echo $EPNR | sed "s/^0*//" )
			EPNR2=$( echo $EPNR2 | sed "s/^0*//" )

	else

		echo "zweistellig mit E"
		echo "$EXTFOLGE" | grep -E -i "([efx\-]|ep\.?)$EPNR2"
		EPCHK=$?

	fi

	if [ $EPCHK -eq 0 ]; then

		echo "*********************************************"

		if [ -z $STNR_2 ]; then

			printf "%s - E%02dE%02d\n" "$(basename "$SERIE_2")" "$EPNR" "$EPNR2"
			PCHECK=0

		else

			printf "%s - S%02dE%02dE%02d\n" "$(basename "$SERIE_2")" "$STNR_2" "$EPNR" "$EPNR2"
			PCHECK=0

		fi

		echo "*********************************************"

	else

		echo "*********************************************"

		if [ -z $STNR_2 ]; then

			printf "%s - E%02d\n" "$(basename "$SERIE_2")" "$EPNR"
			PCHECK=0

		else

			printf "%s - S%02dE%02d\n" "$(basename "$SERIE_2")" "$STNR_2" "$EPNR"
			PCHECK=0

		fi

		echo "*********************************************"

	fi

 DateiOderOrdnerUmbenennen

	return $PCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - EPNR säubern
#-----------------------------------------------------------------------------------------
function GetEPNR
{

	FOLGE_1=$1
	EXTFOLGE=$2
	
	EPNR=$(echo "$EXTFOLGE" | grep -E -o -i "([efx]|ep\.?)[0-9]*" | grep -E -o "[0-9][0-9]{0,2}")
	FRES=$?
	EPNR=$(echo $EPNR | sed q )
	EPNR=$(echo $EPNR | sed "s/^0*//")
#	echo "FRES: " $FRES " | " $EPNR

	if [ $FRES -eq 1 ]; then

#	prüfe ob ordnername richtig 
		DIRSTRING=$( dirname "$FOLGE_1" )
		DIRSTRING=$( basename "$DIRSTRING" )
		
		EXTFOLGE=${EXTFOLGE//1080p/}
		EXTFOLGE=${EXTFOLGE//18p/}
		EXTFOLGE=${EXTFOLGE//720p/}
		EXTFOLGE=${EXTFOLGE//72p/}
		EXTFOLGE=${EXTFOLGE//7p/}
#		EXTFOLGE=${EXTFOLGE//51/}
#		echo "$EXTFOLGE" | sed "/([efx]|ep\.?)[0-9]?51/!s/51//"
		EXTFOLGE=${EXTFOLGE//x264/}
		EXTFOLGE=${EXTFOLGE//h264/}	
		
		EPNR=$(echo "$DIRSTRING" | grep -E -o -i "([efx]|ep\.?)[0-9]*" | grep -E -o "[0-9][0-9]{0,2}")
		ORES=$?
		EPNR=$(echo $EPNR | sed q )
		EPNR=$(echo $EPNR | sed "s/^0*//")
#		echo "ORES: " $ORES " | " $EPNR

		if [ $ORES -eq 1 ]; then

			EPNRCHECK=1

		else

			EPNRCHECK=0

		fi

	else

		EPNRCHECK=0

	fi

	echo "$EPNR"

	return $EPNRCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Episode herausfinden
#-----------------------------------------------------------------------------------------
function getname
{

	FOLGE_1=$1
	STNR_1=$(echo $2 | sed "s/^0*//")
	SERIE_1=$3
	
#	echo "$STNR_1" | sed "s/[0-9]\+\-[0-9]\+//"
# echo "STNRX" "$STNR_1"
  
  echo ">>>>GetName<<<<"
#	prüfe ob Dateiname richtig 
	EXTFOLGE=$(basename "$FOLGE_1")
#	if [ $STNR_1 -ne 1 -a "$FOLGE_1" -ne 8 ]; then
#			EXTFOLGE=${EXTFOLGE//108p/}
#	fi
	# Ersetze in String EXTFOLGE den String recht von "//" mit den string rechts von "/" (empty)
	EXTFOLGE=${EXTFOLGE//1080p/}
	EXTFOLGE=${EXTFOLGE//18p/}
	EXTFOLGE=${EXTFOLGE//720p/}
	EXTFOLGE=${EXTFOLGE//72p/}
	EXTFOLGE=${EXTFOLGE//7p/}
#	EXTFOLGE=${EXTFOLGE//51/}
# 	echo "$EXTFOLGE" | sed "/([efx]|ep\.?)[0-9]?51/!s/51//"
	EXTFOLGE=${EXTFOLGE//x264/}
	EXTFOLGE=${EXTFOLGE//h264/}
	#echo $EXTFOLGE
	echo ">>>>getEPNR<<<<"
	EPNR=$(GetEPNR "$FOLGE_1" "$EXTFOLGE")
	CHK=$?
	echo "$EPNR"

	if [ $CHK -eq 0 ]; then		

		printout "$SERIE_1" "$STNR_1" "$EPNR" "$EXTFOLGE"

	else

#			zweistellig
#	  EPNR=$(basename "$EXTFOLGE" | sed "s/[^0-9]//g" | cut -d " " -f 2 )
 	  echo "$EXTFOLGE"
		EPNR=$(basename "$EXTFOLGE" | grep -E -o -i "[0-9][0-9]{0,2}" | sed q)
	  echo "$EPNR"

		if [[ $EPNR =~ ^[0-9]{1,2}$ ]]; then

			echo "2stellen: " $EPNR
			EPNR=$( echo $EPNR | sed "s/^0*//" )
			printout "$SERIE_1" "$STNR_1" "$EPNR" "$EXTFOLGE"

		else

#				dreistellig
			if [[ $EPNR =~ ^[0-9]{1,3}$ ]]; then

#				EPNR=${EPNR:1}
#				EPNR=$( echo $EPNR | sed "s/^0*//" )
				echo "3stellen: " $EPNR
				printout "$SERIE_1" "$STNR_1" "$EPNR" "$EXTFOLGE"

			else

				logging "$STAFFEL" "nichts" "$SERIE" "3"

			fi

		fi

	fi


}


#-----------------------------------------------------------------------------------------
# FUNKTION - Check Dateityp und Größe
#-----------------------------------------------------------------------------------------
function checkSizeType
{

	echo ">>>>CheckSizeType<<<<"
	FILE="$1"
	file "$FILE" | grep -i -e video -e ebml -e Matroska -e MPEG >/dev/null

  if [ $? -eq 1 ]; then

  	DTYPE=${FILE/*./}
  	grep -i "$DTYPE" ./dtyplist.txt >/dev/null

  fi
	
  if [ $? -eq 0 ]; then

#prüfe ob datei kein Sample ist (größe der Datei)
		SIZE=$( stat -c %s "$FILE" )
		echo "-->" $SIZE " byte"

    if [ $SIZE -gt 20000000 ]; then

   		echo "Videodatei: " $(basename "$FILE")
   		FCHECK=0

   	else

   		echo "Sample: " $(basename "$FILE")
   		FCHECK=1
   		logging "$FILE" "$STNR" "$SERIE" "4"
   		DELETEGLOBAL=$(expr $DELETEGLOBAL + $SIZE)
			#entferne Sample Sofort? NACHDENKEN!!

   	fi

  else

		echo "keine Video Datei: " $(basename "$FILE")
		file "$FILE" | grep -i  -e RAR -e archive >/dev/null

		if [ $? -eq 0 ]; then

			logging "$FILE" "$STNR" "$SERIE" "5"

		else

			logging "$FILE" "$STNR" "$SERIE" "4"
   		DELETEGLOBAL=$(expr $DELETEGLOBAL + $SIZE)
			#entferne Datei Sofort? NACHDENKEN!!

		fi

		FCHECK=1

  fi

	return $FCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function checkfile
{
	echo ">>>>Checkfile<<<<"
	CHFOLGE=$1
	STNR_1=$2
	SERIE_1=$3
	
	if [ -d "$CHFOLGE" ]; then

		find "$CHFOLGE" -type f | while read FILE

		do

			checkSizeType "$FILE"

			if [ $? -eq 0 ]; then

				getname "$FILE" "$STNR_1" "$SERIE_1"

#				if [ $? -eq 0 ]; then

#					FCHECK=0

#				else

#					FCHECK=1

#				fi

			fi

		done

	else

		echo "kein Ordner: " $(basename "$CHFOLGE")
		checkSizeType "$CHFOLGE"

		if [ $? -eq 0 ]; then

			getname "$FILE" "$STNR_1" "$SERIE_1"

#			if [ $? -eq 0 ]; then

#				FCHECK=0

#			else

#				FCHECK=1

#			fi

		else

			logging "$CHFOLGE" "$STNR" "$SERIE" "4"

		fi

	fi

#	echo $FCHECK
	return $FCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION Staffel Ordner auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function checkseason
{
	CHSTAFFEL=$1
	
	if [ -d "$CHSTAFFEL" ]; then

		STNR=$(basename "$CHSTAFFEL")
		STNR=${STNR//720p/}
		STNR=${STNR//1080p/}
		STNR=$(echo "$STNR" | sed "s/[0-9]\+\-[0-9]\+//")
		STNR=$(echo "$STNR" | grep -E -o -i "[0-9][0-9]{0,2}")

		if [[ $STNR =~ ^[0-9]{1,2}$ ]]; then

			SCHECK=0

		else

			SCHECK=1

		fi

	else

		SCHECK=1

	fi

	echo "$STNR"

	return $SCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Taufe
#-----------------------------------------------------------------------------------------
function DateiOderOrdnerUmbenennen
{

echo Datei wird getauft!

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Wenn kein Staffelordner existiert wird dieser erstellt
#-----------------------------------------------------------------------------------------
function StaffelOrdnerErstellen
{

echo Staffelordner wird erstellt

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei wird an vorgesehenen Platz verschoben
#-----------------------------------------------------------------------------------------
function DateiVerschieben
{

echo die Datei wird verschoben

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei oder ein Ordner wird gelöscht
#-----------------------------------------------------------------------------------------
function DateiOderOrdnerLoeschen
{

echo Die Datei oder der Ordner wird gelöscht

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Logging
#-----------------------------------------------------------------------------------------
function logging
{

	FOLGE_1=$1
	STNR_1=$2
	SERIE_1=$3
	LOG=$4
	echo "datei wird geloggt..."

	case $LOG in

		1) 	echo -n "MM01 - Kein Serienordner: " 					>> ./massmove_log.txt	;;
		2)	echo -n "MM02 - Kein Staffelordner oder ähnlches: " 	>> ./massmove_log.txt	;;
		3)	echo -n "MM03 - Taufe nicht möglich: " 					>> ./massmove_log.txt	;;
		4)	echo -n "MM00 - Datei/Ordner entfernt: " 				>> ./massmove_log.txt	;;
		5)	echo -n "MM04 - Archiv Datei: " 						>> ./massmove_log.txt	;;

	esac
	
	echo "Serienname: " $(basename "$SERIE") " | " 				>> ./massmove_log.txt
	echo "Staffel " "$STNR_1" " | " 							>> ./massmove_log.txt
	echo "Datei: " $(basename "$FOLGE_1") " | " 				>> ./massmove_log.txt
	echo -e "Pfad: " "$FOLGE_1" "\r\n"							>> ./massmove_log.txt
	echo -e "-------------------------------------------------------------------------------------------------------------------\r\n" >> ./massmove_log.txt

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


if [ "$1" = "-notest" ] || [ "$2" = "-notest" ] ||  [ "$3" = "-notest" ]; then # Wenn der einer der Aufrufparameter -notest enthält führe Programm im im Echtmodus aus

    TESTMODUS=0

fi


#-----------------------------------------------------------------------------------------
# Hauptroutine: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
for SERIE in $SEARCHPATH*; do # SERIEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

	if [ -d "$SERIE" ]; then # Wenn File existiert und ein Verzeichnis ist dann gehe weite 

		let SERIECOUNT=SERIECOUNT+1 # Zähler für Endprotokoll

		echo "------------------------------------" $( basename "$SERIE" ) "------------------------------------"
		echo "$SERIE" | grep -i -e Film -e movie -e spe[cz]ial -e extra >/dev/null # Suche nach aufgelisteten Wörtern und gebe >=1 (Error) oder 0 (Success) zurück

		if [ $? -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

			for STAFFEL in "$SERIE"/*; do # STAFFELN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

				let SEASONCOUNT=SEASONCOUNT+1  # Zähler für Endprotokoll

				echo "$STAFFEL" | grep -i -e Film -e movie -e spe[cz]ial -e extra >/dev/null # Suche nach aufgelisteten Wörtern und gebe >=1 (Error) oder 0 (Success) zurück

				if [ $? -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

				  	echo ">>>>Checkseason<<<<"
					STNR=$(checkseason "$STAFFEL")

					if [ $? -eq 0 ]; then # Wenn letzter Rückgabe Wert 0 (Success) dann...

						for FOLGE in "$STAFFEL"/*; do # FOLGEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

							let EPCOUNT=EPCOUNT+1 # Zähler für Endprotokoll

							checkfile "$FOLGE" "$STNR" "$SERIE"

						done

					else
						echo "Kein Staffelordner: " $(basename "$STAFFEL") " - WARNING"
						echo "$STNR"
						echo "Prüfe ob gültige Folge..."
						checkfile "$STAFFEL" "$STNR" "$SERIE"
						StaffelOrdnerErstellen
					fi

				else

					echo "---Kein Standard Staffel Ordner---"
					logging "$STAFFEL" "nichts" "$SERIE" "2"

				fi

			done

		else

			echo "---Keine Standardserie---"
			logging "$FOLGE" "nichts" "$SERIE" "1"

		fi	

	else

		echo "ERROR: Syntaxfehler,kein korrekter Pfad angegeben oder keine Seriendateien vorhanden"

	fi

done


#-----------------------------------------------------------------------------------------
# AUSSTIEGSPUNKT
#-----------------------------------------------------------------------------------------
	after=$(date +%s)
	echo "-----------------------------------------------------"
	echo -n "Erfolgreich bearbetet | "
	echo "elapsed time:" $((after - $before)) "seconds"
	echo "bearbeitete Serien: " "$SERIECOUNT"
	echo "bearbeitete Staffeln: " "$SEASONCOUNT"
	echo "bearbeitete Folgen: " "$EPCOUNT"
	echo "gesamt Größe gelöschter Objekte: " "$DELETEGLOBAL" " Bytes"


#-----------------------------------------------------------------------------------------
