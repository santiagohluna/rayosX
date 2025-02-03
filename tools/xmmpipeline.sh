#!/bin/bash

echo '============'
echo 'XMM Pipeline'
echo '============'
echo -e '\nScript para el reprocesamiento y filtrado de la lista de eventos de observaciones de XMM-Newton'

echo -e '\nInicializar HEASoft y SAS.'
heainit
sasinit

## Reprocesamiento de las observaciones

echo -e '\nIngrese el camino hacia el directorio donde se encuentran las observaciones:'
read indir

# 1. Apuntar la variable `SAS_ODF` a la carpeta donde se encuentran las observaciones
export SAS_ODF=${indir}

echo -e '\nLas observaciones se encuentran en:'
echo $SAS_ODF

echo -e '\nIngrese el camino hacia el directorio donde se almacenan los resultados de la reducción:'
read outdir

# Crear el directorio de salida si no existe.
if [ ! -d $outdir ]; then
    mkdir `echo $outdir`
fi

cd ${outdir}

# 2. Luego, ejecutar la tareas cifbuild, la cual crea el archivo `cif.ccf`.

echo -e '\nEjecutar tarea cifbuild.'

cifbuild

# 3. Apuntar la variable `SAS_CCF` a este último archivo:`export SAS_CCF=cif.ccf`.
export SAS_CCF=ccf.cif

# 4. Ejecutar la tarea `odfingest` para actualizar el archivo de resumen `*SUM.SAS`.
echo -e '\nEjecutar tarea odfingest.'

odfingest

# 5. Apuntar la variable `SAS_ODF` al archivo de resumen actualizado: `export SAS_ODF=*SUM.SAS`.
export SAS_ODF=`ls | grep *SUM.SAS`

echo -e $SAS_ODF

#6. Por último, ejecutar las tareas `emproc`y `epproc` para reprocesar las observaciones de los detectores EPIC-MOS y EPIC-pn, respectivamente.

echo -e '\nEjecutar la tarea emproc'

emproc

echo -e '\nEjecutar la tarea epproc'

epproc

## Filtrado de la lista de eventos.

# Antes de comenzar conviene hacer una copia de seguridad de las listas eventos originales detectados por cada cámara. Estos están guardado en los archivos que finalizan `*Evts.ds`:
cp *_*_EPN_*_ImagingEvts.ds PN.fits
cp *_*_EMOS1_*_ImagingEvts.ds M1.fits
cp *_*_EMOS2_*_ImagingEvts.ds M2.fits

# 1. Extraer una curva de luz de eventos singulares (con patrón “0”) a energías por encima de 10 keV para cada cámara (PN, MOS1, MOS2) para identificar los intervalos de alto background, usando la tarea `evselect` de SAS:
evselect table=PN.fits withrateset=Y rateset=ratesPN.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EP && (PI>10000&&PI<12000) && (PATTERN==0)'
evselect table=M1.fits withrateset=Y rateset=ratesM1.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)'
evselect table=M2.fits withrateset=Y rateset=ratesM2.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)'

# 2. Usando la tarea `tabgtigen` se determinan los intervalos de tiempo en los que la curva de luz es baja y constante eligiendo un límite o *threshold* (en cuentas por segundo) para crear el archivo GTI, `EPICgti.fits`: 
tabgtigen table=ratesPN.fits expression='RATE<=0.4' gtiset=PNgti.fits
tabgtigen table=ratesM1.fits expression='RATE<=0.35' gtiset=M1gti.fits
tabgtigen table=ratesM2.fits expression='RATE<=0.35' gtiset=M2gti.fits

# 3. Por último, usamos nuevamente `evselect` para generar la lista de eventos filtrada, `EPICclean.fits`:
evselect table=PN.fits withfilteredset=Y filteredset=PNclean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EP && gti(PNgti.fits,TIME) && (PI>150)'
evselect table=M1.fits withfilteredset=Y filteredset=M1clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M1gti.fits,TIME) && (PI>150)'
evselect table=M2.fits withfilteredset=Y filteredset=M2clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M2gti.fits,TIME) && (PI>150)'

echo -e '\n¡Listo!'
echo -e '\nSeleccionar las regiones correspondientes a la fuente y al background con ds9 para continuar con la generación de productos (espectro y curvas de luz).'

cd ..