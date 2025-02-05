#!/bin/bash

echo '============'
echo 'XMM Products'
echo '============'
echo -e '\nScript para la obtención de curvas de luz y espectros a partir de las observaciones de XMM-Newton'

if [ "$#" -eq 0 ]
then
    echo -e "\nFalta el archivo con los parámetros."
    read -p "Ingrese el nombre del archivo: " -e file
else
    file="$1"
fi

echo $file

i=0
declare -a params=()
while read arg; do
    [[ "$arg" =~ ^#.*$ ]] && continue
    params[i]=$arg
    i=$((i+1))
done < "$file"

echo -e "\nLos parámetros ingresados son:\n"
i=0
for i in "${!params[@]}"; do
    echo "Parámetro $i: '${params[$i]}'."
done

if [ "${#params[@]}" -lt 7 ]; then
    echo -e "\nError: el archivo de parámetros tiene menos de 7 argumentos.\n"
fi

if [ "${#params[@]}" -gt 7 ]; then
    echo -e "\nAdvertencia: el archivo de parámetros tiene más de 7 argumentos.\nLos argumentos extras serán ignorados."
fi

continuar=true

while [ continuar ]; do
    read -p "\n¿Desea agegar o modificar el valor de algún parámetro? [(s)í/(n)o] " -e op
    if [ op="s" ]; then
        read -p "Ingrese el índice del parámetro a modificar: " -e i
        read -p "Ingrese el valor: " -e val
        params[$i] = val

        echo -e "\nLos parámetros ingresados son ahora:\n"
        i=0
        for i in "${!params[@]}"; do
            echo "Parámetro $i: '${params[$i]}'."
        done
    elif [ op="n" ]; then
        continuar=false
    else
        echo -e "\nDebe ingresar 's' o 'n'."
    fi
done

read -p "\nIngrese el nombre del directorio donde se van a almacenar los productos: " -e outdir

# Crear el directorio de salida si no existe.
if [ -d $outdir ]; then
    rm -r $outdir
fi

mkdir `echo $outdir`

cd $outdir

# 1. En primer lugar, se deben inicializar las variables de entorno SAS_ODF y SAS_CCF:

odfdir=${params[0]}

echo $odfdir

export SAS_ODF=${odfdir}

read -p "\nIngrese el camino hacia el directorio donde se almacenan los resultados de la reducción: " -e indir 

pathin="../${indir}"

export SAS_CCF=$pathin/ccf.cif

# Crear el sub-scripts que ejecuta los comandos para la obtención de la curva de luz y del espectro.
echo "#!/bin/bash" > products.sh

# 2. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos.

pnsrcreg=${params[1]}

pnsrc=`cat $pathin/$pnsrcreg`

expsrcpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "$pnsrc")'"

echo "evselect table=$pathin/PNclean.fits energycolumn=PI expression=$expsrcpn withrateset=yes rateset=PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m1srcreg=${params[2]}

m1src=`cat $pathin/$m1srcreg`

exprsrcm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1src}")'"

echo "evselect table=$pathin/M1clean.fits energycolumn=PI expression=$exprsrcm1 withrateset=yes rateset=$pathin/M1_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m2srcreg=${params[3]}

m2src=`cat $pathin/$m2srcreg`

exprsrcm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2src}")'"

echo "evselect table=$pathin/M2clean.fits energycolumn=PI expression=$exprsrcm2 withrateset=yes rateset=$pathin/M2_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 3. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:

pnbkgreg=${params[4]}

pnbkg=`cat $pathin/$pnbkgreg`

exprbgpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=$pathin/PNclean.fits energycolumn=PI expression=$exprbgpn withrateset=yes rateset=PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m1bkgreg=${params[5]}

m1bkg=`cat $pathin/$m1bkgreg`

exprbgm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=$pathin/M1clean.fits energycolumn=PI expression=$exprbgm1 withrateset=yes rateset=M1_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m2bkgreg=${params[6]}

m2bkg=`cat $pathin/$m2bkgreg`

exprbgm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2bkg}")'"

echo "evselect table=$pathin/M2clean.fits energycolumn=PI expression=$exprbgm2 withrateset=yes rateset=M2_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 4. Corrección de las curvas de luz.

echo "epiclccorr srctslist=PN_src_raw.lc eventlist=$pathin/PNclean.fits outset=PN_lccorr.lc bkgtslist=PN_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

echo "epiclccorr srctslist=$pathin/M1_src_raw.lc eventlist=$pathin/M1clean.fits outset=M1_lccorr.lc bkgtslist=M1_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

echo "epiclccorr srctslist=$pathin/M2_src_raw.lc eventlist=$pathin/M2clean.fits outset=M2_lccorr.lc bkgtslist=M2_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

# Obtención de los espectros

# 1. Extraer el espectro de la fuente.

exprPNsrc="'(FLAG==0) && (PATTERN<=4) && ((X,Y) IN "${pnsrc}")'"

echo "evselect table=$pathin/PNclean.fits withspectrumset=yes spectrumset=PN_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression=$exprPNsrc" >> products.sh

exprM1src="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m1src}")'"

echo "evselect table=$pathin/M1clean.fits withspectrumset=yes spectrumset=M1_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM1src" >> products.sh

exprM2src="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m2src}")'"

echo "evselect table=$pathin/M2clean.fits withspectrumset=yes spectrumset=M2_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM2src" >> products.sh

# 2. Extraer el espectro del fondo:

exprPNbg="'(FLAG==0) && (PATTERN<=4) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=$pathin/PNclean.fits withspectrumset=yes spectrumset=PN_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression=$exprPNbg" >> products.sh

exprM1bg="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=$pathin/M1clean.fits withspectrumset=yes spectrumset=M1_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM1bg" >> products.sh

exprM2bg="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m2bkg}")'"

echo "evselect table=$pathin/M2clean.fits withspectrumset=yes spectrumset=M2_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM2bg" >> products.sh

# 3. Calcular el area de las regiones usadas para extraer la fuente y el fondo necesarias para pesar correctamente sus flujos mutuos.

# Para EPIC-pn:
echo "backscale spectrumset=PN_src_spectrum.fits badpixlocation=$pathin/PNclean.fits" >> products.sh
echo "backscale spectrumset=PN_src_bkg_spectrum.pha badpixlocation=$pathin/PNclean.fits" >> products.sh
# Para EPIC-MOS 1:
echo "backscale spectrumset=M1_src_spectrum.fits badpixlocation=$pathin/M1clean.fits" >> products.sh
echo "backscale spectrumset=M1_src_bkg_spectrum.pha badpixlocation=$pathin/M1clean.fits" >> products.sh
# Para EPIC-MOS 2:
echo "backscale spectrumset=M2_src_spectrum.fits badpixlocation=$pathin/M2clean.fits" >> products.sh
echo "backscale spectrumset=M2_src_bkg_spectrum.pha badpixlocation=$pathin/M2clean.fits" >> products.sh

# 4. Usar la tarea rmfgen para crear una matriz de redistribución para el espectro extraído (esto puede llevar más de 30 minutos en computadoras pequeñas):

echo "rmfgen spectrumset=PN_src_spectrum.fits rmfset=PN_src.rmf" >> products.sh
echo "rmfgen spectrumset=M1_src_spectrum.fits rmfset=M1_src.rmf" >> products.sh
echo "rmfgen spectrumset=M2_src_spectrum.fits rmfset=M2_src.rmf" >> products.sh

# 5. Generar la matriz auxiliar. Para fuentes puntuales usar extendedsource=no detmaptype=psf. Para fuentes extendidas usar extendedsource=yes detmaptype=flat o bien generar un mapa de exposición con la tarea expmap).

echo "arfgen spectrumset=PN_src_spectrum.fits arfset=PN_src.arf withrmfset=yes rmfset=PN_src.rmf badpixlocation=$pathin/PNclean.fits extendedsource=no detmaptype=psf" >> products.sh
echo "arfgen spectrumset=M1_src_spectrum.fits arfset=M1_src.arf withrmfset=yes rmfset=M1_src.rmf badpixlocation=$pathin/M1clean.fits extendedsource=no detmaptype=psf" >> products.sh
echo "arfgen spectrumset=M2_src_spectrum.fits arfset=M2_src.arf withrmfset=yes rmfset=M2_src.rmf badpixlocation=$pathin/M2clean.fits extendedsource=no detmaptype=psf" >> products.sh

# 6. Reagrupar el espectro y vincularlo a los archivos asociados tales como el espectro del fondo y las matrices (RMF y ARF). En el ejemplo reagrupamos a un mínimo de 16 cuentas por canal asegurando que el reagrupamiento no exceda un factor 3 en la pérdida de resolución:

echo "specgroup spectrumset=PN_src_spectrum.fits mincounts=16 oversample=3 rmfset=PN_src.rmf arfset=PN_src.arf backgndset=PN_src_bkg_spectrum.pha groupedset=PN_src_grp.pha" >> products.sh
echo "specgroup spectrumset=M1_src_spectrum.fits mincounts=16 oversample=3 rmfset=M1_src.rmf arfset=M1_src.arf backgndset=M1_src_bkg_spectrum.pha groupedset=M1_src_grp.pha" >> products.sh
echo "specgroup spectrumset=M2_src_spectrum.fits mincounts=16 oversample=3 rmfset=M2_src.rmf arfset=M2_src.arf backgndset=M2_src_bkg_spectrum.pha groupedset=M2_src_grp.pha" >> products.sh

chmod +x products.sh

source ./products.sh

rm products.sh

rm *.fits

cd ..

echo -e "\n¡Listo!\n"