#!/bin/bash

#

STRING=abcABC123ABCabc



# Substring ersetzen

echo -e ""

echo -e "Teilstring ersetzen:"

echo -e "--------------------"



echo -n "Original:     "

echo ${STRING}            # Ausgabe des Original-String



echo -n "Variante 1:   "

echo ${STRING/abc/xyz}    # Ersetzt das erste 'abc' durch 'xyz'



echo -n "Variante 2:   "

echo ${STRING//abc/xyz}   # Ersetzt jedes 'abc' durch 'xyz'



echo -n "Variante 3:   "

echo ${STRING/#abc/xyz}   # ersetzt das erste 'abc' durch 'xyz'

                          # nur wenn am Anfang von $STRING 'abc' ist



echo -n "Variante 4:   "

echo ${STRING/%abc/xyz}   # ersetzt das letzte 'abc' durch 'xyz'

                          # nur wenn am Ende von $STRING 'abc' ist



# Teilstring löschen

echo -e ""

echo -e "Teilstring löschen:"

echo -e "-------------------"



echo -n "Original:     "

echo ${STRING}            # Ausgabe des Original-String



echo -n "Variante 1:   "

echo ${STRING#a*C}        # zwischen dem ersten 'a' und dem ersten 'C'

                          # alles löschen (shortest Substring)



echo -n "Variante 2:   "

echo ${STRING##a*C}       # zwischen dem ersten 'a' und dem letzten 'C'

                          # alles löschen (longest Substring)



echo -n "Variante 3:   "

echo ${STRING%b*c}        # zwischen dem letzten 'b' und dem lezten 'c'

                          # alles löschen (shortest Substring)



echo -n "Variante 4:   "

echo ${STRING%%b*c}       # zwischen dem letzten 'b' und dem ersten 'c'

                          # alles löschen (longest Substring)



# Teilstring

echo -e ""

echo -e "Teilstring seperieren 1:"

echo -e "------------------------"



echo -n "Original:     "

echo ${STRING}            # Ausgabe des Original-String



echo -n "Variante 1:   "

echo ${STRING:0}          # Ab Char 0 bis zum Ende



echo -n "Variante 2:   "

echo ${STRING:3}          # Ab Char 3 bis zum ende



echo -n "Variante 3:   "

echo ${STRING:7}          # Ab Char 7 bis zum ende



echo -n "Variante 4:   "

echo ${STRING:3:3}        # Ab Char 3, 3 Chars





# Teilstring Variante 2

echo -e ""

echo -e "Teilstring seperieren 2:"

echo -e "------------------------"



echo -n "Original:     "

echo ${STRING}                 # Ausgabe des Original-String



echo -n "Variante 1:   "

echo `expr substr $STRING 1 3` # Von Char 0, 3 Chars



echo -n "Variante 2:   "

echo `expr match "$STRING" '\(.[b-c]*[A-Z]..[0-9]\)'`

                               # Mittels Regular expression



echo -n "Variante 3:   "

echo `expr "$STRING" : '\(.[b-c]*[A-Z]..[0-9]\)'`

                               # Gleiches Resultat wie 'Variante 2'





# Zählen der Chars

echo -e ""

echo -e "Zählen bis zum Char 'X':"

echo -e "------------------------"



echo -n "Original:     "

echo ${STRING}                  # Ausgabe des Original-String



echo -n "Variante 1:   "

echo `expr match "$STRING" 'abc[A-Z]*.2'`

                                # Zählt die Zeichen 'abc',

                                # gefolgt von einer beliebigen

                                # Zeichenfolge von 'A-Z',

                                # danach bis zum Char '2'



echo -n "Variante 2:   "

echo `expr "$STRING" : 'abc[A-Z]*.2'`

                                # Gleiches Resultat wie 'Variante 1'



echo -n "Variante 3:   "

echo `expr index "$STRING" C12` # Anzahl Chars bis zum Char 'C'





# Länge des Strings

echo -e ""

echo -e "Länge des Strings:"

echo -e "------------------"



echo -n "Original:     "

echo ${STRING}               # Ausgabe des Original-String



echo -n "Variante 1:   "

echo "${#STRING}"            # Anzahl Chars im String



echo -n "Variante 2:   "

echo `expr length "$STRING"` # Anzahl Chars im String

                             # (mit length)



echo -n "Variante 3:   "

echo `expr "$STRING" : '.*'` # Anzahl Chars im String

                             # (mit reguar expression)

