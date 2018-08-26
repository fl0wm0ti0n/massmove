#!/bin/bash
before=$(date +%s)
export DELETEGLOBAL=0
export SERIECOUNT=0
export SEASONCOUNT=0
export EPCOUNT=0
export TESTMODUS=1
export SEARCHPATH=""

#entferne Logdatei wenn vorhanden
rm -f massmove_log.txt

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
function ExtrahiereFolgennummer
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
		
#		EXTFOLGE=${EXTFOLGE//1080p/}
#		EXTFOLGE=${EXTFOLGE//18p/}
#		EXTFOLGE=${EXTFOLGE//720p/}
#		EXTFOLGE=${EXTFOLGE//72p/}
#		EXTFOLGE=${EXTFOLGE//7p/}
#		EXTFOLGE=${EXTFOLGE//51/}
#		echo "$EXTFOLGE" | sed "/([efx]|ep\.?)[0-9]?51/!s/51//"
#		EXTFOLGE=${EXTFOLGE//x264/}
#		EXTFOLGE=${EXTFOLGE//h264/}	
		
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
function PruefeDateinameUndExtrahiereRelevanteInformationen
{

	FOLGE_1=$1
	STNR_1=$(echo $2 | sed "s/^0*//")
	SERIE_1=$3
	
#	echo "$STNR_1" | sed "s/[0-9]\+\-[0-9]\+//"
# echo "STNRX" "$STNR_1"
  
  echo ">>>>PruefeDateinameUndExtrahiereRelevanteInformationen<<<<"
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
	echo ">>>>ExtrahiereFolgennummer<<<<"
	EPNR=$(ExtrahiereFolgennummer "$FOLGE_1" "$EXTFOLGE")
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

				SchreibeInLogdatei "$STAFFEL" "$STNR_1" "$SERIE" "3"

			fi

		fi

	fi


}


#-----------------------------------------------------------------------------------------
# FUNKTION - Check Dateityp und Größe
#-----------------------------------------------------------------------------------------
function PruefeDateiGroeßeUndTyp
{

	echo ">>>>PruefeDateiGroeßeUndTyp<<<<" >&2

	FILE="$1"
	SIZE=$(PruefeDateiGroeße "$FILE")

	PruefeDateiTyp "$FILE"

	if [ $? -eq 0 ]; then # Wenn der geforderte Dateityp enthalten ist überprüfe die Dateigröße

	#prüfe ob datei kein Sample ist (größe der Datei)

		if [ $SIZE -gt 20000000 ]; then # Wenn datei über 20MB groß ist dann...

			echo "Videodatei: " $(basename "$FILE") >&2
			FCHECK=0

		else

			echo "Sample: " $(basename "$FILE") >&2
			FCHECK=1

			SchreibeInLogdatei "$FILE" "$STNR" "$SERIE" "4"
			#entferne Sample Sofort? NACHDENKEN!!
			AddGesamtGeloescht "$SIZE"

		fi

  	else

		echo "keine Video Datei: " $(basename "$FILE") >&2
		file "$FILE" | grep -i  -e RAR -e archive >/dev/null

		if [ $? -eq 0 ]; then

			SchreibeInLogdatei "$FILE" "$STNR" "$SERIE" "5"
			#entferne Datei Sofort? NACHDENKEN!!	
			AddGesamtGeloescht "$SIZE"

		else

			SchreibeInLogdatei "$FILE" "$STNR" "$SERIE" "4"
			#entferne Datei Sofort? NACHDENKEN!!			
			AddGesamtGeloescht "$SIZE"

		fi

			FCHECK=1

  	fi

    echo "$FCHECK,$DELETEGLOBAL"
	#return $FCHECK

}

#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeDateiTyp
{

	FILE=$1
	RETURN=0

	file "$FILE" | grep -i -e video -e ebml -e Matroska -e MPEG >/dev/null # Prüfe ob Datei einer der gelisteten Dateitypen ist

	if [ $? -eq 1 ]; then # Wenn Dateityp keiner der zuvor gelisteten Dateitypen ist dann prüfe ob Datei einer der in der dtyplist.txt enthaltenen Dateiendungen hat

		RETURN=1

  		DTYPE=${FILE/*./}
  		grep -i "$DTYPE" ./dtyplist.txt >/dev/null
		  
		if [ $? -eq 0 ]; then

			RETURN=0

		fi

  	fi

	return $RETURN

}


#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function IfAufBlacklistReturnTrue
{

	FILE=$1
	RETURN=1

	if [ -e ./blacklist.txt ]; then
		
		DTYPE=${FILE/*./}
		grep -i "$DTYPE" ./blacklist.txt >/dev/null
			
		if [ $? -eq 0 ]; then

			RETURN=0

		fi

	fi

	return $RETURN

}


#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeDateiGroeße
{

	FILE=$1

	SIZE=$( stat -c %s "$FILE" ) # Eruriere Byteanzahl der aktuellen Datei

	echo $SIZE

}

#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function AddGesamtGeloescht
{

	SIZE=$1

	echo "Datei mit" $SIZE "Bytes wird gelöscht" >&2

	DELETED=$(sed -n 1p ./delbytes.txt)

	echo $((SIZE + $DELETED)) > ./delbytes.txt

	echo "Status insgesamt gelöscht:" $((SIZE + $DELETED)) "Bytes" >&2 

}


#-----------------------------------------------------------------------------------------
# FUNKTION Datei auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeDatei
{
	echo ">>>>PruefeDatei<<<<" >&2
	CHFOLGE=$1
	STNR_1=$2
	SERIE_1=$3
	
	if [ -d "$CHFOLGE" ]; then # Wenn es sich um einen Ordner handelt dann...

		echo "Folge ist Ordner: " $(basename "$CHFOLGE") >&2
		echo "Suche Datei..." >&2
		find "$CHFOLGE" -type f | while read FILE # Suche Dateien im Ordner

		# An dieser stelle könnte man DateiVerschieben und DateiOderOrdnerLoeschen aufrufen. es muss aber darauf geachtet werden, dass es sich um einen Folgenordner handelt und nicht ein Staffelordner

		do

			echo "Datei gefunden: " $(basename "$FILE") >&2
			PruefeDateiGroeßeUndTyp "$CHFOLGE"

			if [ $RES1 -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...

				PruefeDateinameUndExtrahiereRelevanteInformationen "$FILE" "$STNR_1" "$SERIE_1"

#				if [ $? -eq 0 ]; then

#					FCHECK=0

#				else

#					FCHECK=1

#				fi

			fi

		done

	else

		echo "Folge ist kein Ordner: " $(basename "$CHFOLGE") >&2
		PruefeDateiGroeßeUndTyp "$CHFOLGE"

		if [ $? -eq 0 ]; then # Wenn es sich um zulässige Folge handelt dann...

			PruefeDateinameUndExtrahiereRelevanteInformationen "$FILE" "$STNR_1" "$SERIE_1"

#			if [ $? -eq 0 ]; then

#				FCHECK=0

#			else

#				FCHECK=1

#			fi

		else

			SchreibeInLogdatei "$CHFOLGE" "$STNR" "$SERIE" "4"

		fi

	fi

#	echo $FCHECK
	return $FCHECK

}


#-----------------------------------------------------------------------------------------
# FUNKTION Staffel Ordner auf richtigkeit prüfen
#-----------------------------------------------------------------------------------------
function PruefeStaffelOrdner
{
	CHSTAFFEL=$1
	
	echo ">>>>PruefeStaffelOrdner<<<<"  >&2

	if [ -d "$CHSTAFFEL" ]; then # Wenn es sich um einen Ordner handelt dann...

		# Extrahiere nur die reine Staffel Nummer
		STNR=$(basename "$CHSTAFFEL")
		STNR=${STNR//1080p/}
		STNR=${STNR//18p/}
		STNR=${STNR//720p/}
		STNR=${STNR//72p/}
		STNR=${STNR//7p/}
		STNR=${STNR//x264/}
		STNR=${STNR//h264/}
		STNR=$(echo "$STNR" | sed "s/[0-9]\+\-[0-9]\+//")
		STNR=$(echo "$STNR" | grep -E -o -i "[0-9][0-9]{0,2}")

		echo "Staffelname: Staffel $STNR" >&2

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
# FUNKTION - Prüfe ob Datei bereits Korrekt bennannt ist
#-----------------------------------------------------------------------------------------
function IfDateiBereitsRichtigReturnFalse
{

DATEI1=$1
DATEI2=$2

echo "Die Datei '$DATEI1' ist ident mit der Datei '$DATEI1' es muss nichts getan werden benannt ist" >&2

return 1

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Taufe
#-----------------------------------------------------------------------------------------
function DateiOderOrdnerUmbenennen
{

DATEI1=$1
DATEI2=$2

echo "die $DATEI1 wird umbenannt in $DATEI2" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Wenn kein Staffelordner existiert wird dieser erstellt
#-----------------------------------------------------------------------------------------
function StaffelOrdnerErstellen
{

PFAD=$1
STAFFEL=$2

echo "Staffelordner $STAFFEL wird im PFad $PFAD erstellt" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei wird an vorgesehenen Platz verschoben
#-----------------------------------------------------------------------------------------
function DateiVerschieben
{

DATEI=$1
PFAD=$2

echo "die $DATEI wird verschoben in $PFAD" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - Eine Datei oder ein Ordner wird gelöscht
#-----------------------------------------------------------------------------------------
function DateiOderOrdnerLoeschen
{

DATEI=$1

echo "Die Datei oder der Ordner $DATEI wird gelöscht" >&2

}


#-----------------------------------------------------------------------------------------
# FUNKTION - SchreibeInLogdatei
#-----------------------------------------------------------------------------------------
function SchreibeInLogdatei
{

	FOLGE_1=$1
	STNR_1=$2
	SERIE_1=$3
	LOG=$4
	echo "datei wird geloggt..." >&2

	case $LOG in

		1) 	echo -n "Fehlecode MM01 | Kein Serienordner: " 						>> ./massmove_log.txt	;;
		2)	echo -n "Fehlecode MM02 | Kein Staffelordner oder ähnlches: " 		>> ./massmove_log.txt	;;
		3)	echo -n "Fehlecode MM03 | Taufe nicht möglich: " 					>> ./massmove_log.txt	;;
		4)	echo -n "Fehlecode MM00 | Datei/Ordner entfernt: " 					>> ./massmove_log.txt	;;
		5)	echo -n "Fehlecode MM04 | Archiv Datei: " 							>> ./massmove_log.txt	;;
		6)	echo -n "Fehlecode MM05 | Datei musste nicht bearbeitet werden: " 	>> ./massmove_log.txt	;;

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
# INNERSTE SCHLEIFE - FOLGEN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function InnersteSchleife_Folgen
{

SERIE=$1
STAFFEL=$2
STNR=$3

	for FOLGE in "$STAFFEL"/*; do # FOLGEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

		let EPCOUNT=EPCOUNT+1 # Zähler für Endprotokoll

		PruefeDatei "$FOLGE" "$STNR" "$SERIE"

	done
}

#-----------------------------------------------------------------------------------------
# MITTLERE SCHLEIFE - STAFFELN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function MittlereSchleife_Staffeln
{

SERIE=$1

for STAFFEL in "$SERIE"/*; do # STAFFELN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

	let SEASONCOUNT=SEASONCOUNT+1  # Zähler für Endprotokoll

	echo "$STAFFEL" | grep -i -e Film -e movie -e spe[cz]ial -e extra >/dev/null # Suche nach aufgelisteten Wörtern und gebe >=1 (Error) oder 0 (Success) zurück

	if [ $? -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

		STNR=$(PruefeStaffelOrdner "$STAFFEL")

		if [ $? -eq 0 ]; then # Wenn letzter Rückgabe Wert 0 (Success) dann...

			InnersteSchleife_Folgen "$SERIE" "$STAFFEL" "$STNR"

		else
			echo "Kein Staffelordner: " $(basename "$STAFFEL") " - WARNING"  >&2
			echo "$STNR"  >&2
			echo "Prüfe ob gültige Folge..."  >&2
			PruefeDatei "$STAFFEL" "$STNR" "$SERIE"

			StaffelOrdnerErstellen
		fi

		echo "PruefeStaffelOrdner Erorierte Staffelnummer: " "$STNR" >&2

	else

		echo "---Kein Standard Staffel Ordner---" >&2
		SchreibeInLogdatei "$STAFFEL" "nichts" "$SERIE" "2"

	fi

done

}


#-----------------------------------------------------------------------------------------
# OBERSTE SCHLEIFE - SERIEN: Serien Ordner nach Serien, Staffeln und Folgen durchsuchen
#-----------------------------------------------------------------------------------------
function ObersteSchleife_Serien
{

for SERIE in $SEARCHPATH*; do # SERIEN SCHLEIFE - Für jedes gefundene Element im angegebenen Pfad einen Schleifendurchlauf

	if [ -d "$SERIE" ]; then # Wenn File existiert und ein Verzeichnis ist dann gehe weite 

		let SERIECOUNT=SERIECOUNT+1 # Zähler für Endprotokoll

		echo "------------------------------------" $( basename "$SERIE" ) "------------------------------------" >&2
		echo "$SERIE" | grep -i -e Film -e movie -e spe[cz]ial -e extra >/dev/null # Suche nach aufgelisteten Wörtern und gebe >=1 (Error) oder 0 (Success) zurück

		if [ $? -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

			IfAufBlacklistReturnTrue "$( basename "$SERIE" )"
			if [ $? -eq 1 ]; then # Wenn letzter Rückgabe Wert 1 (Error) dann...

			MittlereSchleife_Staffeln "$SERIE"

			else

			echo "Serie '$( basename "$SERIE" )' ist auf der Ausnahmeliste Überspringe diese Serie" >&2

			fi	
		else

			echo "---Keine Standardserie---" >&2
			SchreibeInLogdatei "$FOLGE" "nichts" "$SERIE" "1"

		fi	

	else

		echo "ERROR: Syntaxfehler,kein korrekter Pfad angegeben oder keine Seriendateien vorhanden" >&2

	fi

done

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
	echo "bearbeitete Serien: " "$SERIECOUNT"
	echo "bearbeitete Staffeln: " "$SEASONCOUNT"
	echo "bearbeitete Folgen: " "$EPCOUNT"
	echo "gesamt Größe gelöschter Objekte: " $(sed -n 1p ./delbytes.txt) " Bytes"

	echo "----------------------------------------------------------------\r\n" 				>> ./massmove_log.txt
	echo -n "Erfolgreich bearbetet | "														>> ./massmove_log.txt
	echo -e "elapsed time:" $((after - $before)) "seconds\r\n"								>> ./massmove_log.txt
	echo -e "bearbeitete Serien: " "$SERIECOUNT\r\n"										>> ./massmove_log.txt
	echo -e "bearbeitete Staffeln: " "$SEASONCOUNT\r\n"										>> ./massmove_log.txt
	echo -e "bearbeitete Folgen: " "$EPCOUNT\r\n"											>> ./massmove_log.txt
	echo "gesamt Größe gelöschter Objekte: " $(sed -n 1p ./delbytes.txt) " Bytes"			>> ./massmove_log.txt

#-----------------------------------------------------------------------------------------
