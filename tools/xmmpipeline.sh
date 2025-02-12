#!/bin/bash

echo -e '\n============'
echo -e 'XMM Pipeline'
echo -e '============'
echo -e '\nScript para el reprocesamiento y filtrado de la lista de eventos de observaciones de XMM-Newton'

# Resetear las variables de entorno necesarias.
unset SAS_CCF
unset SAS_ODF

# Ruta esperada
RUTA_ESPERADA="/home/shluna/Proyectos/rayosX/data/reduction"

# Obtener la ruta actual
RUTA_ACTUAL=$(pwd)

echo -e "\nVerificando si el directorio de trabajo es $RUTA_ESPERADA"

# Comparar rutas
if [ "$RUTA_ACTUAL" != "$RUTA_ESPERADA" ]; then
    cd $RUTA_ESPERADA
    echo -e "\nSe cambió el directorio de trabajo a $(pwd)"
fi

if [ ! -d xmm ]; then
    mkdir xmm
fi
cd xmm

## Reprocesamiento de las observaciones

# Verificar si hay observaciones para procesar.
obs_path="$RXPATH/data/obs/xmm"
readarray obs < <(ls $obs_path)
if [ "${#obs[@]}" -eq 0 ]; then
    printf "¡Advertencia!: No existen observaciones a procesar. Debe descargarlas primero."
    exit 1
fi

if [ "$#" -eq 0 ]
then
    printf "\nLista de observaciones posibles a procesar:\n\n"
    for i in ${!obs[@]}
    do 
        printf "$((i+1)). ObsID: %s" "${obs[$i]}"
        i=$((i+1))
    done
    printf "\nIngrese el índice identificador de la observación o el ObdId: "
    read -e id
    obsid=$(printf %s "${obs[$((id-1))]}")
else
    obsid=$1
fi

printf "\nEl ID de la observación seleccionada es: %s.\n" "$obsid"

# Cadena para el nombre de la carpeta de salida y log.
STAMP="obsID_"$obsid"_"$(date +'d%Y%m%d_t%H%M%S')

# Crear la carpeta donde se van a almacenar los archivos que resultan de la reducción.

outdir=$STAMP

if [ ! -d $outdir ]; then
    mkdir $(echo $outdir)
fi

cd ${outdir}

# Crear el archivo log
LOG_FILE=$STAMP"xmmpipeline_log.txt"

echo '=======================' >> $LOG_FILE
echo 'XMM Pipeline - Log file' >> $LOG_FILE
echo '=======================' >> $LOG_FILE

echo -e '\nInicializar HEASoft y SAS.' | tee -a  $LOG_FILE
heainit
sasinit | tee -a  $LOG_FILE

# Almacenar la ruta hacia los archivos con las observaciones a procesar.
indir=/home/shluna/Proyectos/rayosX/data/obs/xmm/$obsid/ODF

# 1. Apuntar la variable `SAS_ODF` a la carpeta donde se encuentran las observaciones
export SAS_ODF=${indir}

echo -e "\nLas observaciones se encuentran en: $SAS_ODF" | tee -a  $LOG_FILE

echo -e "\nLos archivos generados por el reprocesamiento y el filtrado se guardan en: $outdir." | tee -a  $LOG_FILE

# 2. Luego, ejecutar la tareas cifbuild, la cual crea el archivo `cif.ccf`.

echo -e '\nEjecutando tarea cifbuild.' | tee -a  $LOG_FILE

cifbuild | tee -a  $LOG_FILE

# 3. Apuntar la variable `SAS_CCF` a este último archivo:`export SAS_CCF=cif.ccf`.
export SAS_CCF=ccf.cif

# 4. Ejecutar la tarea `odfingest` para actualizar el archivo de resumen `*SUM.SAS`.
echo -e '\nEjecutando tarea odfingest.' | tee -a  $LOG_FILE

odfingest | tee -a  $LOG_FILE

# 5. Apuntar la variable `SAS_ODF` al archivo de resumen actualizado: `export SAS_ODF=*SUM.SAS`.
export SAS_ODF=`ls | grep *SUM.SAS`

echo -e "\nArchivo de resumen actualizado: $SAS_ODF" | tee -a  $LOG_FILE

#6. Por último, ejecutar las tareas `emproc`y `epproc` para reprocesar las observaciones de los detectores EPIC-MOS y EPIC-pn, respectivamente.

echo -e '\nEjecutando tarea emproc.' | tee -a  $LOG_FILE

emproc | tee -a  $LOG_FILE

echo -e '\nEjecutando tarea epproc.' | tee -a  $LOG_FILE

epproc | tee -a  $LOG_FILE

## Filtrado de la lista de eventos.

# Antes de comenzar conviene hacer una copia de seguridad de las listas eventos originales detectados por cada cámara. Estos están guardado en los archivos que finalizan `*Evts.ds`:
cp *_*_EPN_*_ImagingEvts.ds PN.fits
cp *_*_EMOS1_*_ImagingEvts.ds M1.fits
cp *_*_EMOS2_*_ImagingEvts.ds M2.fits

echo -e "\nIdentificando los intervalos de alto background." | tee -a  $LOG_FILE

# 1. Extraer una curva de luz de eventos singulares (con patrón “0”) a energías por encima de 10 keV para cada cámara (PN, MOS1, MOS2) para identificar los intervalos de alto background, usando la tarea `evselect` de SAS:
evselect table=PN.fits withrateset=Y rateset=ratesPN.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EP && (PI>10000&&PI<12000) && (PATTERN==0)' | tee -a  $LOG_FILE
evselect table=M1.fits withrateset=Y rateset=ratesM1.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' | tee -a  $LOG_FILE
evselect table=M2.fits withrateset=Y rateset=ratesM2.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)' | tee -a  $LOG_FILE

echo -e "\nDeterminando los intervalos de tiempo en los que la curva de luz es baja y constante" | tee -a  $LOG_FILE

# 2. Usando la tarea `tabgtigen` se determinan los intervalos de tiempo en los que la curva de luz es baja y constante eligiendo un límite o *threshold* (en cuentas por segundo) para crear el archivo GTI, `EPICgti.fits`: 
tabgtigen table=ratesPN.fits expression='RATE<=0.4' gtiset=PNgti.fits | tee -a  $LOG_FILE
tabgtigen table=ratesM1.fits expression='RATE<=0.35' gtiset=M1gti.fits | tee -a  $LOG_FILE
tabgtigen table=ratesM2.fits expression='RATE<=0.35' gtiset=M2gti.fits | tee -a  $LOG_FILE

echo -e "\nGenerando la lista de eventos filtrada." | tee -a  $LOG_FILE

# 3. Por último, usamos nuevamente `evselect` para generar la lista de eventos filtrada, `EPICclean.fits`:
evselect table=PN.fits withfilteredset=Y filteredset=PNclean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EP && gti(PNgti.fits,TIME) && (PI>150)' | tee -a  $LOG_FILE
evselect table=M1.fits withfilteredset=Y filteredset=M1clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M1gti.fits,TIME) && (PI>150)' | tee -a  $LOG_FILE
evselect table=M2.fits withfilteredset=Y filteredset=M2clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M2gti.fits,TIME) && (PI>150)' | tee -a  $LOG_FILE

echo -e '\n¡Listo!' | tee -a  $LOG_FILE
echo -e '\nAbrir los archivos PNclean.fits, M1clean.fits y M2clean.fits con ds9 y seleccionar las regiones correspondientes a la fuente y al background para continuar con la generación de productos (espectro y curvas de luz).\n Guardar las regiones usando las coordenadas físicas.\n'

cd $RUTA_ESPERADA