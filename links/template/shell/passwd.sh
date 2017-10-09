#!/bin/bash  

a=(a b c d e A B C D E F @ $ % ^ 0 1 2 3 4 5 6 7 8 9)  

for ((i=0;i<10;i++));do  

        echo -n ${a[$RANDOM % ${#a[@]}]}  

done  

echo
