#!/bin/bash

printf '\n============' 
printf '\nXMM Products'
printf '\n============'
printf '\n\nScript para la obtención de curvas de luz y espectros a partir de las observaciones de XMM-Newton\n'

# Resetear las variables de entorno necesarias.
unset SAS_CCF
unset SAS_ODF

# Ruta al directorio tools
TOOLSPATH="/home/shluna/Proyectos/rayosX/tools"

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data/xmm"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

echo -e "\nVerificando si el directorio de trabajo es $RUTA_ESPERADA"

# Comparar rutas
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd $RUTA_ESPERADA
    echo -e "\nSe cambió el directorio de trabajo a $(pwd)"
fi

readarray obs < <(ls)
if [ "${#obs[@]}" -eq 0 ]; then
    printf "¡Advertencia!: No existen observaciones a procesar. Debe descargarlas primero."
fi

if [ "$#" -eq 0 ]
then
    printf "\nLista de observaciones posibles a procesar:\n\n"
    for i in ${!obs[@]}
    do 
        printf "$((i+1)). ObsID: %s" "${obs[$i]}"
        i=$((i+1))
    done
    printf "\nIngrese el índice identificador de la observación: "
    read -e id
    obsid=$(printf %s "${obs[$((id-1))]}")
else
    obsid=$1
fi

# Cambiar directorio de trabajo al correspondiente ObsID.
cd $obsid
echo -e "\nSe cambió el directorio de trabajo a $(pwd)"

# Buscar los directorios en la carpeta donde se guardan las reducciones y almacenarlos en un array:
readarray x < <(find . -type d -name "PLO_*")

printf "\nSe encontraron %s directorios con datos de reducción de observaciones correspondientes al ObsID %s:\n\n" "${#x[@]}" "$obsid"
if [ "${#x[@]}" -gt 1 ]; then
    for i in ${!x[@]}
    do 
        printf "Directorio $((i+1)): ${x[$i]}"
    done

    printf "\nIngrese el índice del directorio donde se almacenan los resultados de la reducción: "
    read idir

    indir=$(printf %s ${x[$((idir-1))]})
else
    indir=$(printf %s ${x[0]})
fi

printf "\nEl directorio seleccionado es: %s" "$indir"{regfiles[$id]}

readarray regfiles < <(find . -type f -name "*.reg")

printf "\nLos archivos de regiones son:\n"
for i in "${!regfiles[@]}"; do
    printf "Archivo %s: %s" "$i" "${regfiles[$i]}"
done

# Asignar los archivos a las variables correspondientes.

cd $indir
echo -e "\nSe cambió el directorio de trabajo a $(pwd)"

printf "\nIngrese el nombre del archivo de región de la fuente para la cámara EPIC-PN: "
read -e regfile
params[0]=$regfile
printf "\nIngrese el nombre del archivo de región de la fuente para la cámara EPIC-MOS1: "
read -e regfile
params[1]=$regfile
printf "\nIngrese el nombre del archivo de región de la fuente para la cámara EPIC-MOS2: "
read -e regfile
params[2]=$regfile
printf "\nIngrese el nombre del archivo de región del background para la cámara EPIC-PN: "
read -e regfile
params[3]=$regfile
printf "\nIngrese el nombre del archivo de región del background para la cámara EPIC-MOS1: "
read -e regfile
params[4]=$regfile
printf "\nIngrese el nombre del archivo de región del background para la cámara EPIC-MOS2: "
read -e regfile
params[5]=$regfile

printf "\nLos archivos de regiones son:\n"
printf "\n1. Fuente (cámara EPIC-PN): %s" "${params[0]}"
printf "\n2. Fuente (cámara EPIC-MOS1): %s" "${params[1]}"
printf "\n3. Fuente (cámara EPIC-MOS2): %s" "${params[2]}"
printf "\n4. Background (cámara EPIC-PN): %s" "${params[3]}"
printf "\n5. Background (cámara EPIC-MOS1): %s" "${params[4]}"
printf "\n6. Background (cámara EPIC-MOS2): %s" "${params[5]}"

while true; do
    printf "\n¿Desea modificar algunos de los archivos? [(s)í/(n)o] "
    read op
    case $op in
        [Ss]* ) 
            printf "\nIngrese el número identificador del archivo a modificar: "
            read i
            printf "\nLos archivos de regiones encontrados en el directorio %s son:\n" "$indir"
            for i in "${!regfiles[@]}"; do
                printf "Archivo %s: %s" "$i" "${regfiles[$i]}"
            done
            printf "\nIngrese el indice del archivo a seleccionar: "
            read val
            regfiles[$i]=$((val-1))

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

cd ..
echo -e "\nSe cambió el directorio de trabajo a $(pwd)"

# Cadena para el nombre de la carpeta de salida y log.
STAMP=$(date +'d%Y%m%d_t%H%M%S')

# Crear la carpeta donde se van a almacenar los archivos que resultan de la reducción.

outdir="products_$STAMP"
echo -e "\nLos productos se van a guardar en $outdir"

# Crear el directorio de salida si no existe.
mkdir -p $(echo $outdir)

cd $outdir

# Crear archivo de log
LOG_FILE="xmmproducts_"$STAMP".log"

printf '\n=======================' >> $LOG_FILE
printf '\nXMM Products - Log file' >> $LOG_FILE
printf '\n=======================' >> $LOG_FILE

# 1. En primer lugar, se deben inicializar las variables de entorno SAS_ODF y SAS_CCF:

# Almacenar la ruta hacia los archivos con las observaciones a procesar.
odfdir=/home/shluna/Proyectos/rayosX/data/xmm/$obsid/ODF

# Apuntar la variable de entorne SAS_CCF al archivo 'ccf.cif'.
SAS_CCF=$(find $odfdir -type f -name "ccf.cif")
export SAS_CCF=$SAS_CCF
echo -e "\nVariable de entorno SAS_CCF configurada: $SAS_CCF" | tee -a "$LOG_FILE"
echo -e "\n----------------------" >> "$LOG_FILE"

# Apuntar la variable SAS_ODF al archivo de resumen generado por odfingest.
SAS_ODF=$(find $odfdir -type f -name "*SUM.SAS")
export SAS_ODF=$SAS_ODF
echo -e "\nVariable de entorno SAS_ODF configurada: $SAS_ODF" | tee -a "$LOG_FILE"
echo -e "\n----------------------" >> "$LOG_FILE"

# Ruta al archivo con los comandos
FILE_PATH="$TOOLSPATH/xmmproducts.cmnds"

# Inicializar un array vacío
COMMANDS=()

# Leer el archivo línea por línea
while IFS= read -r line; do
    # Quitar espacios en blanco al inicio y fin
    line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Ignorar líneas vacías o que comienzan con "#" (comentarios)
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi

    # Agregar el comando al array
    COMMANDS+=("$line")
done < "$FILE_PATH"

# # Arreglo con los comando a ejecutar:
# COMMANDS=(
#     # 2. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos.
#     "evselect table=$indir/PNclean.evts energycolumn=PI expression='(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "${params[0]}")' withrateset=yes rateset=PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes"
#     "evselect table=$indir/M1clean.evts energycolumn=PI expression='(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${params[1]}")' withrateset=yes rateset=$indir/M1_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes"
#     "evselect table=$indir/M2clean.evts energycolumn=PI expression='(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${params[2]}")' withrateset=yes rateset=$indir/M2_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" 
#     # 3. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:
#     "evselect table=$indir/PNclean.evt energycolumn=PI expression='(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "${params[3]}")' withrateset=yes rateset=PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes"
#     "evselect table=$indir/M1clean.evts energycolumn=PI expression='(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${params[4]}")' withrateset=yes rateset=M1_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes"
#     "evselect table=$indir/M2clean.evts energycolumn=PI expression='(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${params[5]}")' withrateset=yes rateset=M2_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes"
#     # 4. Corrección de las curvas de luz.
#     "epiclccorr srctslist=PN_src_raw.lc eventlist=$indir/PNclean.evt outset=PN_lccorr.lc bkgtslist=PN_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes"
#     "epiclccorr srctslist=$indir/M1_src_raw.lc eventlist=$indir/M1clean.evts outset=M1_lccorr.lc bkgtslist=M1_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes"
#     "epiclccorr srctslist=$indir/M2_src_raw.lc eventlist=$indir/M2clean.evts outset=M2_lccorr.lc bkgtslist=M2_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes"
#     #
#     # Obtención de los espectros
#     #
#     # 1. Extraer el espectro de la fuente.
#     "evselect table=$indir/PNclean.evt withspectrumset=yes spectrumset=PN_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN ${params[0]})'"
#     "evselect table=$indir/M1clean.evts withspectrumset=yes spectrumset=M1_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${params[1]})'"
#     "evselect table=$indir/M2clean.evts withspectrumset=yes spectrumset=M2_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${params[2]})'"
#     # 2. Extraer el espectro del fondo:
#     "evselect table=$indir/PNclean.evt withspectrumset=yes spectrumset=PN_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN ${params[3]})'"
#     "evselect table=$indir/M1clean.evts withspectrumset=yes spectrumset=M1_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${params[4]})'"
#     "evselect table=$indir/M2clean.evts withspectrumset=yes spectrumset=M2_src_bkg_spectrum.pha energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${params[5]})'"
#     # 3. Calcular el area de las regiones usadas para extraer la fuente y el fondo necesarias para pesar correctamente sus flujos mutuos.
#     ## Para EPIC-pn:
#     "backscale spectrumset=PN_src_spectrum.fits badpixlocation=$indir/PNclean.evt"
#     "backscale spectrumset=PN_src_bkg_spectrum.pha badpixlocation=$indir/PNclean.evt"
#     ## Para EPIC-MOS 1:
#     "backscale spectrumset=M1_src_spectrum.fits badpixlocation=$indir/M1clean.evts"
#     "backscale spectrumset=M1_src_bkg_spectrum.pha badpixlocation=$indir/M1clean.evts"
#     ## Para EPIC-MOS 2:
#     "backscale spectrumset=M2_src_spectrum.fits badpixlocation=$indir/M2clean.evts"
#     "backscale spectrumset=M2_src_bkg_spectrum.pha badpixlocation=$indir/M2clean.evts"
#     # 4. Usar la tarea rmfgen para crear una matriz de redistribución para el espectro extraído (esto puede llevar más de 30 minutos en computadoras pequeñas):
#     "rmfgen spectrumset=PN_src_spectrum.fits rmfset=PN_src.rmf"
#     "rmfgen spectrumset=M1_src_spectrum.fits rmfset=M1_src.rmf"
#     "rmfgen spectrumset=M2_src_spectrum.fits rmfset=M2_src.rmf"
#     # 5. Generar la matriz auxiliar. Para fuentes puntuales usar extendedsource=no detmaptype=psf. Para fuentes extendidas usar extendedsource=yes detmaptype=flat o bien generar un mapa de exposición con la tarea expmap).
#     "arfgen spectrumset=PN_src_spectrum.fits arfset=PN_src.arf withrmfset=yes rmfset=PN_src.rmf badpixlocation=$indir/PNclean.evt extendedsource=no detmaptype=psf"
#     "arfgen spectrumset=M1_src_spectrum.fits arfset=M1_src.arf withrmfset=yes rmfset=M1_src.rmf badpixlocation=$indir/M1clean.evts extendedsource=no detmaptype=psf"
#     "arfgen spectrumset=M2_src_spectrum.fits arfset=M2_src.arf withrmfset=yes rmfset=M2_src.rmf badpixlocation=$indir/M2clean.evts extendedsource=no detmaptype=psf"
#     # 6. Reagrupar el espectro y vincularlo a los archivos asociados tales como el espectro del fondo y las matrices (RMF y ARF). En el ejemplo reagrupamos a un mínimo de 16 cuentas por canal asegurando que el reagrupamiento no exceda un factor 3 en la pérdida de resolución:
#     "specgroup spectrumset=PN_src_spectrum.fits mincounts=16 oversample=3 rmfset=PN_src.rmf arfset=PN_src.arf backgndset=PN_src_bkg_spectrum.pha groupedset=PN_src_grp.pha"
#     "specgroup spectrumset=M1_src_spectrum.fits mincounts=16 oversample=3 rmfset=M1_src.rmf arfset=M1_src.arf backgndset=M1_src_bkg_spectrum.pha groupedset=M1_src_grp.pha"
#     "specgroup spectrumset=M2_src_spectrum.fits mincounts=16 oversample=3 rmfset=M2_src.rmf arfset=M2_src.arf backgndset=M2_src_bkg_spectrum.pha groupedset=M2_src_grp.pha"
# )

echo -e "\nComandos ejecutados" >> "$LOG_FILE"
echo -e "===================\n" >> "$LOG_FILE"

for CMD in "${COMMANDS[@]}"; do
    echo "- $CMD" >> "$LOG_FILE"
done

# Ejecutar los comandos definidos en el arreglo "COMMANDS".
for CMD in "${COMMANDS[@]}"; do
    echo -e "\nEjecutando: $CMD" | tee -a "$LOG_FILE"
    echo >> "$LOG_FILE" 2>&1
    eval "$CMD" >> "$LOG_FILE" 2>&1
    echo -e "\n----------------------" >> "$LOG_FILE"
done

echo -e "\n¡Listo!" >> "$LOG_FILE"

echo -e "\nEjecución finalizada [$(date +'%d/%m/%Y - %H:%M:%S')]. Ver $LOG_FILE para detalles.\n" | tee -a "../$LOG_FILE"

rm *.fits

cd $RUTA_ESPERADA