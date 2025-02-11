#!/bin/bash

printf '\n============' 
printf '\nXMM Products'
printf '\n============'
printf '\n\nScript para la obtención de curvas de luz y espectros a partir de las observaciones de XMM-Newton\n'

if [ "$#" -eq 0 ]
then
    printf "\nIngrese el ID de la observación: "
    read obsid
else
    obsid="$1"
fi

# Cadena para el nombre de la carpeta de salida y log.
STAMP="obsID_"$obsid"_"$(date +'d%Y%m%d_t%H%M%S')

# Crear archivo de log

LOG_FILE=$STAMP"xmmproducts_log.txt"

printf '\n=======================' >> $LOG_FILE
printf '\nXMM Products - Log file' >> $LOG_FILE
printf '\n=======================' >> $LOG_FILE

# 1. En primer lugar, se deben inicializar las variables de entorno SAS_ODF y SAS_CCF:

export SAS_ODF="$RXPATH/data/obs/xmm/$obsid/ODF"

reduction_path="$RXPATH/data/reduction/xmm"

# Buscar los directorios en la carpeta donde se guardan las reducciones y almacenarlos en un array:
readarray x < <(ls $reduction_path | grep obsID_$obsid)

printf "\nSe encontraron %s directorios con datos de reducción de observaciones correspondientes al ObsID %s:\n\n" "${#x[@]}" "$obsid"
if [ "${#x[@]}" -gt 1 ]; then
    for i in ${!x[@]}
    do 
        printf "Directorio $i: ${x[$i]}"
        i=$((i+1))
    done

    printf "\nIngrese el índice del directorio donde se almacenan los resultados de la reducción: "
    read idir

    indir=$reduction_path/$(printf %s ${x[$idir]})
else
    indir=$reduction_path/$(printf %s ${x[0]})
fi

printf "\nEl directorio seleccionado es: %s" "$indir"

export SAS_CCF=$indir/ccf.cif

# Crear el sub-scripts que ejecuta los comandos para la obtención de la curva de luz y del espectro.
echo "#!/bin/bash" > products.sh

readarray regfiles < <(ls $indir/*.reg)

printf "\nLos archivos de regiones son:\n"
for i in "${!regfiles[@]}"; do
    printf "Archivo %s: %s" "$i" "${regfiles[$i]}"
done

# Asignar los archivos a las variables correspondientes

printf "\nIngrese el índice correspondiente al archivo de región de la fuente para la cámara EPIC-PN: "
read id
params[0]=${regfiles[$id]}
printf "\nIngrese el índice correspondiente al archivo de región de la fuente para la cámara EPIC-MOS1: "
read id
params[1]=${regfiles[$id]}
printf "\nIngrese el índice correspondiente al archivo de región de la fuente para la cámara EPIC-MOS2: "
read id
params[2]=${regfiles[$id]}
printf "\nIngrese el índice correspondiente al archivo de región del background para la cámara EPIC-PN: "
read id
params[3]=${regfiles[$id]}
printf "\nIngrese el índice correspondiente al archivo de región del background para la cámara EPIC-MOS1: "
read id
params[4]=${regfiles[$id]}
printf "\nIngrese el índice correspondiente al archivo de región del background para la cámara EPIC-MOS2: "
read id
params[5]=${regfiles[$id]}

printf "\nLos archivos de regiones son ahora:\n"
printf "\nFuente (cámara EPIC-PN): %s" "${params[0]}"
printf "\nFuente (cámara EPIC-MOS1): %s" "${params[1]}"
printf "\nFuente (cámara EPIC-MOS2): %s" "${params[2]}"
printf "\nBackground (cámara EPIC-PN): %s" "${params[3]}"
printf "\nBackground (cámara EPIC-MOS1): %s" "${params[4]}"
printf "\nBackground (cámara EPIC-MOS2): %s" "${params[5]}"

while true; do
    printf "\n¿Desea modificar algunos de los archivos? [(s)í/(n)o] "
    read op
    case $op in
        [Ss]* ) 
            printf "\nIngrese el índice del archivo a modificar: "
            read i
            printf "\nLos archivos de regiones encontrados en el directorio %s son:\n" "$indir"
            for i in "${!regfiles[@]}"; do
                printf "Archivo %s: %s" "$i" "${regfiles[$i]}"
            done
            printf "\nIngrese el indice del archivo a seleccionar: "
            read val
            regfiles[$i]=$val

            echo -e "\nLos parámetros ingresados son ahora:\n"
            i=0
            for i in "${!regfiles[@]}"; do
                printf "Archivo %s: %s." "$i" "${regfiles[$i]}"
            done
        ;;
        [Nn]* ) break;;
        * ) echo -e "\nDebe ingresar 's' o 'n'.";;
    esac
done

# Crear la carpeta donde se van a almacenar los archivos que resultan de la reducción.

outdir=$STAMP
echo -e "\nLos productos se van a guardar en $outdir"

# Crear el directorio de salida si no existe.
if [ -d $outdir ]; then
    rm -r $outdir
fi

mkdir $(echo $outdir)

cd $outdir

# 2. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos.

pnsrcreg=${params[0]}

pnsrc=`cat $pnsrcreg`

expsrcpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "$pnsrc")'"

echo "evselect table=$indir/PNclean.fits energycolumn=PI expression=$expsrcpn withrateset=yes rateset=PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m1srcreg=${params[1]}

m1src=`cat $m1srcreg`

exprsrcm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1src}")'"

echo "evselect table=$indir/M1clean.fits energycolumn=PI expression=$exprsrcm1 withrateset=yes rateset=$indir/M1_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m2srcreg=${params[2]}

m2src=`cat $m2srcreg`

exprsrcm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2src}")'"

echo "evselect table=$indir/M2clean.fits energycolumn=PI expression=$exprsrcm2 withrateset=yes rateset=$indir/M2_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 3. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:

pnbkgreg=${params[3]}

pnbkg=`cat $pnbkgreg`

exprbgpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=$indir/PNclean.fits energycolumn=PI expression=$exprbgpn withrateset=yes rateset=PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m1bkgreg=${params[4]}

m1bkg=`cat $m1bkgreg`

exprbgm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=$indir/M1clean.fits energycolumn=PI expression=$exprbgm1 withrateset=yes rateset=M1_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

m2bkgreg=${params[5]}

m2bkg=`cat $m2bkgreg`

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