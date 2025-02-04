#!/bin/bash

echo '============'
echo 'XMM Products'
echo '============'
echo -e '\nScript para la obtención de curvas de luz y espectros a partir de las observaciones de XMM-Newton'

echo -e '\nInicializar HEASoft y SAS.'
heainit
sasinit

echo -e '\nIngrese el nombre del directorio donde se van a almacenar los productos:'
read outdir

# Crear el directorio de salida si no existe.
if [ ! -d $outdir ]; then
    mkdir `echo $outdir`
fi

# 1. En primer lugar, se deben inicializar las variables de entorno SAS_ODF y SAS_CCF:

echo -e '\nIngrese el camino hacia el directorio donde se encuentran las observaciones:'
read indir

export SAS_ODF=${indir}

echo -e '\nIngrese el camino hacia el directorio donde se almacenan los resultados de la reducción:'
read indir

export SAS_CCF=${indir}/ccf.cif

# 2. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos.

echo -e '\nIngrese el archivo que guarda la región correspondiente a la fuente registrada en EPIC-PN:'
read pnsrcreg

pnsrc=`cat $pnsrcreg`

evselect table=${indir}/PNclean.fits energycolumn=PI expression='(FLAG==0)&& (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN ${pnsrc}' withrateset=yes rateset=${outdir}/PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes

echo -e '\nIngrese el archivo que guarda la región correspondiente a la fuente registrada en EPIC-MOS1:'
read m1srcreg

m1src=`cat $m1srcreg`

evselect table=${indir}/M1clean.fits energycolumn=PI expression='(FLAG==0)&& (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN ${m1src}' withrateset=yes rateset=${indir}/M1_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes

echo -e '\nIngrese el archivo que guarda la región correspondiente a la fuente registrada en EPIC-MOS2:'
read m2srcreg

m2src=`cat $m2srcreg`

evselect table=${indir}/M2clean.fits energycolumn=PI expression='(FLAG==0)&& (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN ${m2src}' withrateset=yes rateset=${indir}/M2_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes

# 3. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:

echo -e '\nIngrese el archivo que guarda la región correspondiente al background registrada en EPIC-PN:'
read pnbkgreg

pnbkg=`cat $pnbkgreg`

evselect table=${indir}/PNclean.fits energycolumn=PI expression='(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN ${pnbkg}' withrateset=yes rateset=${outdir}/PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes

echo -e '\nIngrese el archivo que guarda la región correspondiente al background registrada en EPIC-MOS1:'
read m1bkgreg

m1bkg=`cat $m1bkgreg`

evselect table=${indir}/M1clean.fits energycolumn=PI expression='(FLAG==0)&& (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN ${m1bkg}' withrateset=yes rateset=${outdir}/M1_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes

echo -e '\nIngrese el archivo que guarda la región correspondiente al background registrada en EPIC-MOS2:'
read m2bkgreg

m2bkg=`cat $m2bkgreg`

evselect table=${indir}/M2clean.fits energycolumn=PI expression='(FLAG==0)&& (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN ${m2bkg}' withrateset=yes rateset=${outdir}/M2_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes

# 4. Corrección de las curvas de luz.

epiclccorr srctslist=${outdir}/PN_src_raw.lc eventlist=${indir}/PNclean.fits outset=${outdir}/PN_lccorr.lc bkgtslist=${outdir}/PN_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes

epiclccorr srctslist=${indir}/M1_src_raw.lc eventlist=${indir}/M1clean.fits outset=${outdir}/M1_lccorr.lc bkgtslist=${outdir}/M1_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes

epiclccorr srctslist=${indir}/M2_src_raw.lc eventlist=${indir}/M2clean.fits outset=${outdir}/M2_lccorr.lc bkgtslist=${outdir}/M2_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes

# Obtención de los espectros

# 1. Extraer el espectro de la fuente.

evselect table=${indir}/PNclean.fits withspectrumset=yes spectrumset=${outdir}/PN_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN  ${pnsrc})'

evselect table=${indir}/M1clean.fits withspectrumset=yes spectrumset=${outdir}/M1_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${m1src})'

evselect table=${indir}/M2clean.fits withspectrumset=yes spectrumset=${outdir}/M2_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${m2src})'

# 2. Extraer el espectro del fondo:

evselect table=${indir}/PNclean.fits withspectrumset=yes spectrumset=${outdir}/PN_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN ${pnbkg})'

evselect table=${indir}/M1clean.fits withspectrumset=yes spectrumset=${outdir}/M1_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${m1bkg})'

evselect table=${indir}/M2clean.fits withspectrumset=yes spectrumset=${outdir}/M2_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression='(FLAG==0) && (PATTERN<=12) && ((X,Y) IN ${m2bkg})'

# 3. Calcular el area de las regiones usadas para extraer la fuente y el fondo necesarias para pesar correctamente sus flujos mutuos.

# Para EPIC-pn:
backscale spectrumset=${outdir}/PN_src_spectrum.fits badpixlocation=${indir}/PNclean.fits
backscale spectrumset=${outdir}/PN_src_bkg_spectrum.fits badpixlocation=${indir}/PNclean.fits
# Para EPIC-MOS 1:
backscale spectrumset=${outdir}/M1_src_spectrum.fits badpixlocation=${indir}/M1clean.fits
backscale spectrumset=${outdir}/M1_src_bkg_spectrum.fits badpixlocation=${indir}/M1clean.fits
# Para EPIC-MOS 2:
backscale spectrumset=${outdir}/M2_src_spectrum.fits badpixlocation=${indir}/M2clean.fits
backscale spectrumset=${outdir}/M2_src_bkg_spectrum.fits badpixlocation=${indir}/M2clean.fits

# 4. Usar la tarea rmfgen para crear una matriz de redistribución para el espectro extraído (esto puede llevar más de 30 minutos en computadoras pequeñas):

rmfgen spectrumset=${outdir}/PN_src_spectrum.fits rmfset=${outdir}/PN_src.rmf
rmfgen spectrumset=${outdir}/M1_src_spectrum.fits rmfset=${outdir}/M1_src.rmf
rmfgen spectrumset=${outdir}/M2_src_spectrum.fits rmfset=${outdir}/M2_src.rmf

# 5. Generar la matriz auxiliar. Para fuentes puntuales usar extendedsource=no detmaptype=psf. Para fuentes extendidas usar extendedsource=yes detmaptype=flat o bien generar un mapa de exposición con la tarea expmap).

arfgen spectrumset=${outdir}/PN_src_spectrum.fits arfset=${outdir}/PN_src.arf withrmfset=yes rmfset=${outdir}/PN_src.rmf badpixlocation=${indir}/PNclean.fits extendedsource=no detmaptype=psf
arfgen spectrumset=${outdir}/M1_src_spectrum.fits arfset=${outdir}/M1_src.arf withrmfset=yes rmfset=${outdir}/M1_src.rmf badpixlocation=${indir}/M1clean.fits extendedsource=no detmaptype=psf
arfgen spectrumset=${outdir}/M2_src_spectrum.fits arfset=${outdir}/M2_src.arf withrmfset=yes rmfset=${outdir}/M2_src.rmf badpixlocation=${indir}/M2clean.fits extendedsource=no detmaptype=psf

# 6. Reagrupar el espectro y vincularlo a los archivos asociados tales como el espectro del fondo y las matrices (RMF y ARF). En el ejemplo reagrupamos a un mínimo de 16 cuentas por canal asegurando que el reagrupamiento no exceda un factor 3 en la pérdida de resolución:

specgroup spectrumset=${outdir}/PN_src_spectrum.fits mincounts=16 oversample=3 rmfset=${outdir}/PN_src.rmf arfset=${outdir}/PN_src.arf backgndset=${outdir}/PN_src_bkg_spectrum.fits groupedset=${outdir}/PN_src_grp.fits
specgroup spectrumset=${outdir}/M1_src_spectrum.fits mincounts=16 oversample=3 rmfset=${outdir}/M1_src.rmf arfset=${outdir}/M1_src.arf backgndset=${outdir}/M1_src_bkg_spectrum.fits groupedset=${outdir}/M1_src_grp.fits
specgroup spectrumset=${outdir}/M2_src_spectrum.fits mincounts=16 oversample=3 rmfset=${outdir}/M2_src.rmf arfset=${outdir}/M2_src.arf backgndset=${outdir}/M2_src_bkg_spectrum.fits groupedset=${outdir}/M2_src_grp.fits

echo -e "\n¡Listo!\n"