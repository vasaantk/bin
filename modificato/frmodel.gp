set title "Trajectory of an Object at 1836-0712 and  2.50kpc away in Flat Rotation Model
set size 1.5, 0.725
set xrange [] reverse
set xlabel "Displacement in RA (mas)"
set ylabel "Displacement in Dec (mas)"
set terminal postscript portrait color
set output "frmodel1836-0712.ps"
plot \
"galrot.dat" title "Galact. Rot./year" with vector , \
"solmot.dat" title "Solar Motion/year" with vector , \
"galsol.dat" title "Sum of Above     " with vector , \
"paralx.dat" title "Annual Parallax  " with linespoints, \
"combmt.dat" title "Combined Motion  " with linespoints 
