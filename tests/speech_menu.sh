#!/bin/bash
# Install first:
# sudo apt update && sudo apt install -y \
# pocketsphinx \
# pocketsphinx-en-us \
# sox \
# libpulse-dev \
# alsa-utils

# Pfade zu den Sprachmodellen
MODEL_DIR="/usr/share/pocketsphinx/model/en-us"
ACOUSTIC_MODEL="$MODEL_DIR/en-us"
LANGUAGE_MODEL="$MODEL_DIR/en-us.lm.bin"
DICTIONARY="$MODEL_DIR/cmudict-en-us.dict"

# Funktion: Tastendruck abfangen
wait_for_keypress() {
  echo "Drücken Sie eine beliebige Taste, um fortzufahren..."
# Terminal in den Rohmodus setzen
  stty -icanon -echo
  dd bs=1 count=1 2>/dev/null
# Terminal in den Normalmodus zurücksetzen
  stty icanon echo
}

while true; do
  echo "=== Spracherkennungs-Menü ==="
  echo "1: Option Eins"
  echo "2: Option Zwei"
  echo "3: Option Drei"
  echo "4: Option Vier"
  echo "5: Option Fünf"
  echo "quit: Beenden"

  wait_for_keypress

  echo "Aufnahme läuft... Drücken Sie eine beliebige Taste, um die Aufnahme zu beenden."
  arecord -f S16_LE -r 16000 input.wav &
  RECORD_PID=$!

  wait_for_keypress
  kill $RECORD_PID
  echo "Aufnahme beendet."
  echo "Verarbeite die Audioeingabe..."
# 150 Millisekunden Fading am Anfang einfügen. Tastendruck hallt noch im Raum nach.
  sox input.wav processed.wav fade t 0:0:0.150
# Nutzung einer Schlüsselwort-Datei, die die statistische Häufigkeit der Erkennung im Kontext erhöht
  pocketsphinx_continuous \
      -hmm "$ACOUSTIC_MODEL" \
      -lm "$LANGUAGE_MODEL" \
      -dict "$DICTIONARY" \
      -kws_threshold 1e-20 \
      -kws "keywords.txt" \
      -infile processed.wav -logfn logs.txt > result_raw.txt

# Automatische Korrektur anwenden: Wir haben ein Mapping File für häufige Verhörer und deren richtige Entsprechung
  while IFS=" " read -r wrong correct; do
    sed -i "s/\b$wrong\b/$correct/g" result_raw.txt
  done < mapping.txt

# Endgültiges Ergebnis
cat result_raw.txt > result.txt
 
# Ergebnis auslesen
  RECOGNIZED=$(grep -oE "mode fm|one|two|three|four|five|quit" result.txt)
  echo "Debug: Result - $(cat result.txt)"
  echo "Debug: Recognized - $RECOGNIZED"

# Auswahl treffen
  case $RECOGNIZED in
  one)
    echo "Auswahl: Option 1"
    ;;
  two)
    echo "Auswahl: Option 2"
    ;;
  three)
    echo "Auswahl: Option 3"
    ;;
  four)
    echo "Auswahl: Option 4"
    ;;
  five)
    echo "Auswahl: Option 5"
    ;;
  quit)
    echo "Programm wird beendet. Auf Wiedersehen!"
    break
    ;;
  *)
    echo "Ungültige Auswahl. Bitte erneut versuchen."
    ;;
  esac
done
