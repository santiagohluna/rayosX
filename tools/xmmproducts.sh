#!/bin/bash

echo '============'
echo 'XMM Products'
echo '============'
echo -e '\nScript para la obtención de curvas de luz y espectros a partir de las observaciones de XMM-Newton'

if [ "$#" -eq 0 ]
then
    echo
    read -p "Ingrese el ID de la observación: " -e obsid
else
    obsid="$1"
fi

# 1. En primer lugar, se deben inicializar las variables de entorno SAS_ODF y SAS_CCF:

export SAS_ODF=/home/shluna/Proyectos/rayosX/data/obs/xmm/$obsid/ODF

reduction_path=/home/shluna/Proyectos/rayosX/data/reduction/xmm

# Buscar los directorios en la carpeta donde se guardan las reducciones y almacenarlos en un array:
readarray x < <(ls $reduction_path | grep obsID_$obsid)

if [ "$#x[@]}" -gt 1 ]; then
    for i in ${!x[@]}
    do 
        printf "%s" "Directorio $i: ${x[$i]}"
        i=$((i+1))
    done

    read -p "Ingrese el índice del directorio donde se almacenan los resultados de la reducción: " -e idir
    indir=$reduction_path/(printf %s ${x[$idir]})
else
    indir=$reduction_path/(printf %s ${x[0]})
fi

echo -e "\nEl directorio seleccionado es: $indir"

export SAS_CCF=$indir/ccf.cif

# Crear el sub-scripts que ejecuta los comandos para la obtención de la curva de luz y del espectro.
echo "#!/bin/bash" > products.sh

# while read arg; do
#     [[ "$arg" =~ ^#.*$ ]] && continue
#     params[i]=$arg
#     i=$((i+1))
# done < "$file"

readarray params < <(ls *.reg)

echo -e "\nLos archivos de regiones son:\n"
i=0
for i in "${!params[@]}"; do
    printf "Archivo %s: %s." "$i" "${params[$i]}"
done

# if [ "${#params[@]}" -lt 7 ]; then
#     echo -e "\nError: el archivo de parámetros tiene menos de 7 argumentos.\n"
# fi

# if [ "${#params[@]}" -gt 7 ]; then
#     echo -e "\nAdvertencia: el archivo de parámetros tiene más de 7 argumentos.\nLos argumentos extras serán ignorados."
# fi

while true; do
    echo
    read -p "¿Desea agregar o modificar algunos de los archivos? [(s)í/(n)o] " -e op
    case $op in
        [Ss]* ) 
            echo
            read -p "Ingrese el índice del archivo a modificar: " -e i
            echo
            read -p "Ingrese el valor: " -e val
            params[$i]=$val

            echo -e "\nLos parámetros ingresados son ahora:\n"
            i=0
            for i in "${!params[@]}"; do
                printf "Archivo %s: %s." "$i" "${params[$i]}"
            done
        ;;
        [Nn]* ) break;;
        * ) echo -e "\nDebe ingresar 's' o 'n'.";;
    esac
done

# Cadena para el nombre de la carpeta de salida y log.
STAMP="obsID_"$obsid"_"$(date +'d%d%m%Y_t%H%M%S')

# Crear la carpeta donde se van a almacenar los archivos que resultan de la reducción.

outdir=$STAMP
echo -e "\nLos productos se van a guardar en $outdir"

# Crear el directorio de salida si no existe.
if [ -d $outdir ]; then
    rm -r $outdir
fi

mkdir `echo $outdir`

cd $outdir

# 2. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos.

pnsrcreg=${params[1]}

pnsrc=`cat $indir/$pnsrcreg`

expsrcpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "$pnsrc")'"

echo "evselect table=$indir/PNclean.fits energycolumn=PI expression=$expsrcpn withrateset=yes rateset=PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m1srcreg=${params[2]}

m1src=`cat $indir/$m1srcreg`

exprsrcm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1src}")'"

echo "evselect table=$indir/M1clean.fits energycolumn=PI expression=$exprsrcm1 withrateset=yes rateset=$indir/M1_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m2srcreg=${params[3]}

m2src=`cat $indir/$m2srcreg`

exprsrcm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2src}")'"

echo "evselect table=$indir/M2clean.fits energycolumn=PI expression=$exprsrcm2 withrateset=yes rateset=$indir/M2_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 3. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:

pnbkgreg=${params[4]}

pnbkg=`cat $indir/$pnbkgreg`

exprbgpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=$indir/PNclean.fits energycolumn=PI expression=$exprbgpn withrateset=yes rateset=PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m1bkgreg=${params[5]}

m1bkg=`cat $indir/$m1bkgreg`

exprbgm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=$indir/M1clean.fits energycolumn=PI expression=$exprbgm1 withrateset=yes rateset=M1_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m2bkgreg=${params[6]}

m2bkg=`cat $indir/$m2bkgreg`

exprbgm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2bkg}")'"

echo "evselect table=$indir/M2clean.fits energycolumn=PI expression=$exprbgm2 withrateset=yes rateset=M2_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 4. Corrección de las curvas de luz.

echo "epiclccorr srctslist=PN_src_raw.lc eventlist=$indir/PNclean.fits outset=PN_lccorr.lc bkgtslist=PN_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

echo "epiclccorr srctslist=$indir/M1_src_raw.lc eventlist=$indir/M1clean.fits outset=M1_lccorr.lc bkgtslist=M1_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

echo "epiclccorr srctslist=$indir/M2_src_raw.lc eventlist=$indir/M2clean.fits outset=M2_lccorr.lc bkgtslist=M2_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

# Obtención de los espectros

# 1. Extraer el espectro de la fuente.

exprPNsrc="'(FLAG==0) && (PATTERN<=4) && ((X,Y) IN "${pnsrc}")'"

echo "evselect table=$indir/PNclean.fits withspectrumset=yes spectrumset=PN_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression=$exprPNsrc" >> products.sh

exprM1src="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m1src}")'"

echo "evselect table=$indir/M1clean.fits withspectrumset=yes spectrumset=M1_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM1src" >> products.sh

exprM2src="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m2src}")'"

echo "evselect table=$indir/M2clean.fits withspectrumset=yes spectrumset=M2_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM2src" >> products.sh

# 2. Extraer el espectro del fondo:

exprPNbg="'(FLAG==0) && (PATTERN<=4) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=$indir/PNclean.fits withspectrumset=yes spectrumset=PN_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression=$exprPNbg" >> products.sh

exprM1bg="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=$indir/M1clean.fits withspectrumset=yes spectrumset=M1_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM1bg" >> products.sh

exprM2bg="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m2bkg}")'"

echo "evselect table=$indir/M2clean.fits withspectrumset=yes spectrumset=M2_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM2bg" >> products.sh

# 3. Calcular el area de las regiones usadas para extraer la fuente y el fondo necesarias para pesar correctamente sus flujos mutuos.

# Para EPIC-pn:
echo "backscale spectrumset=PN_src_spectrum.fits badpixlocation=$indir/PNclean.fits" >> products.sh
echo "backscale spectrumset=PN_src_bkg_spectrum.pha badpixlocation=$indir/PNclean.fits" >> products.sh
# Para EPIC-MOS 1:
echo "backscale spectrumset=M1_src_spectrum.fits badpixlocation=$indir/M1clean.fits" >> products.sh
echo "backscale spectrumset=M1_src_bkg_spectrum.pha badpixlocation=$indir/M1clean.fits" >> products.sh
# Para EPIC-MOS 2:
echo "backscale spectrumset=M2_src_spectrum.fits badpixlocation=$indir/M2clean.fits" >> products.sh
echo "backscale spectrumset=M2_src_bkg_spectrum.pha badpixlocation=$indir/M2clean.fits" >> products.sh

# 4. Usar la tarea rmfgen para crear una matriz de redistribución para el espectro extraído (esto puede llevar más de 30 minutos en computadoras pequeñas):

echo "rmfgen spectrumset=PN_src_spectrum.fits rmfset=PN_src.rmf" >> products.sh
echo "rmfgen spectrumset=M1_src_spectrum.fits rmfset=M1_src.rmf" >> products.sh
echo "rmfgen spectrumset=M2_src_spectrum.fits rmfset=M2_src.rmf" >> products.sh

# 5. Generar la matriz auxiliar. Para fuentes puntuales usar extendedsource=no detmaptype=psf. Para fuentes extendidas usar extendedsource=yes detmaptype=flat o bien generar un mapa de exposición con la tarea expmap).

echo "arfgen spectrumset=PN_src_spectrum.fits arfset=PN_src.arf withrmfset=yes rmfset=PN_src.rmf badpixlocation=$indir/PNclean.fits extendedsource=no detmaptype=psf" >> products.sh
echo "arfgen spectrumset=M1_src_spectrum.fits arfset=M1_src.arf withrmfset=yes rmfset=M1_src.rmf badpixlocation=$indir/M1clean.fits extendedsource=no detmaptype=psf" >> products.sh
echo "arfgen spectrumset=M2_src_spectrum.fits arfset=M2_src.arf withrmfset=yes rmfset=M2_src.rmf badpixlocation=$indir/M2clean.fits extendedsource=no detmaptype=psf" >> products.sh

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