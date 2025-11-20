#!/bin/bash

# Zielordner, in den die Dateien verschoben werden sollen
ZIELORDNER="alle_multimediadateien"

# Erstelle den Zielordner, falls er nicht existiert
mkdir -p "$ZIELORDNER"

# Liste der Multimediadateiendungen (kann erweitert werden)
DATEIENDUNGEN=("*.mp3" "*.mp4" "*.avi" "*.mkv" "*.jpg" "*.jpeg" "*.png" "*.gif" "*.flac" "*.wav" "*.ogg" "*.mov" "*.webm")

# Durchsuche alle Unterverzeichnisse und verschiebe die Dateien
for endung in "${DATEIENDUNGEN[@]}"; do
    find . -type f -name "$endung" | while read -r datei; do
        # Extrahiere den Dateinamen
        dateiname=$(basename "$datei")

        # Zielpfad erstellen
        ziel="$ZIELORDNER/$dateiname"

        # Falls die Datei bereits existiert, füge einen nummerischen Suffix hinzu
        counter=1
        while [ -e "$ziel" ]; do
            ziel="${ZIELORDNER%/}/$(basename "$dateiname" .${dateiname##*.})_$counter.${dateiname##*.}"
            ((counter++))
        done

        # Verschiebe die Datei
        mv -v "$datei" "$ziel"
    done
done

echo "Alle Multimediadateien wurden nach '$ZIELORDNER' verschoben."
