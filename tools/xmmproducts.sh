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
read odfdir

export SAS_ODF=${odfdir}

echo -e '\nIngrese el camino hacia el directorio donde se almacenan los resultados de la reducción:'
read indir

export SAS_CCF=${indir}/ccf.cif

# Crear el sub-scripts que ejecuta los comandos para la obtención de la curva de luz y del espectro.
echo "#!/bin/bash" > products.sh

# 2. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos.

echo -e '\nIngrese el nombre del archivo que guarda la región correspondiente a la fuente registrada en EPIC-PN:'
read pnsrcreg

pnsrc=`cat ${indir}/$pnsrcreg`

expsrcpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "$pnsrc")'"

echo "evselect table=${indir}/PNclean.fits energycolumn=PI expression=$expsrcpn withrateset=yes rateset=${outdir}/PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

echo -e '\nIngrese el nombre del archivo que guarda la región correspondiente a la fuente registrada en EPIC-MOS1:'
read m1srcreg

m1src=`cat ${indir}/$m1srcreg`

exprsrcm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1src}")'"

echo "evselect table=${indir}/M1clean.fits energycolumn=PI expression=$exprsrcm1 withrateset=yes rateset=${indir}/M1_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

echo -e '\nIngrese el nombre del archivo que guarda la región correspondiente a la fuente registrada en EPIC-MOS2:'
read m2srcreg

m2src=`cat ${indir}/$m2srcreg`

exprsrcm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2src}")'"

echo "evselect table=${indir}/M2clean.fits energycolumn=PI expression=$exprsrcm2 withrateset=yes rateset=${indir}/M2_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 3. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:

echo -e '\nIngrese el nombre del archivo que guarda la región correspondiente al background registrada en EPIC-PN:'
read pnbkgreg

pnbkg=`cat ${indir}/$pnbkgreg`

exprbgpn="'(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=${indir}/PNclean.fits energycolumn=PI expression=$exprbgpn withrateset=yes rateset=${outdir}/PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

echo -e '\nIngrese el nombre del archivo que guarda la región correspondiente al background registrada en EPIC-MOS1:'
read m1bkgreg

m1bkg=`cat ${indir}/$m1bkgreg`

exprbgm1="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=${indir}/M1clean.fits energycolumn=PI expression=$exprbgm1 withrateset=yes rateset=${outdir}/M1_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

echo -e '\nIngrese el nombre del archivo que guarda la región correspondiente al background registrada en EPIC-MOS2:'
read m2bkgreg

m2bkg=`cat ${indir}/$m2bkgreg`

exprbgm2="'(FLAG==0) && (PATTERN<=12) && (PI in [300:10000]) && ((X,Y) IN "${m2bkg}")'"

echo "evselect table=${indir}/M2clean.fits energycolumn=PI expression=$exprbgm2 withrateset=yes rateset=${outdir}/M2_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes" >> products.sh

# 4. Corrección de las curvas de luz.

echo "epiclccorr srctslist=${outdir}/PN_src_raw.lc eventlist=${indir}/PNclean.fits outset=${outdir}/PN_lccorr.lc bkgtslist=${outdir}/PN_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

echo "epiclccorr srctslist=${indir}/M1_src_raw.lc eventlist=${indir}/M1clean.fits outset=${outdir}/M1_lccorr.lc bkgtslist=${outdir}/M1_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

echo "epiclccorr srctslist=${indir}/M2_src_raw.lc eventlist=${indir}/M2clean.fits outset=${outdir}/M2_lccorr.lc bkgtslist=${outdir}/M2_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes" >> products.sh

# Obtención de los espectros

# 1. Extraer el espectro de la fuente.

exprPNsrc="'(FLAG==0) && (PATTERN<=4) && ((X,Y) IN "${pnsrc}")'"

echo "evselect table=${indir}/PNclean.fits withspectrumset=yes spectrumset=${outdir}/PN_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression=$exprPNsrc" >> products.sh

exprM1src="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m1src}")'"

echo "evselect table=${indir}/M1clean.fits withspectrumset=yes spectrumset=${outdir}/M1_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM1src" >> products.sh

exprM2src="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m2src}")'"

echo "evselect table=${indir}/M2clean.fits withspectrumset=yes spectrumset=${outdir}/M2_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM2src" >> products.sh

# 2. Extraer el espectro del fondo:

exprPNbg="'(FLAG==0) && (PATTERN<=4) && ((X,Y) IN "${pnbkg}")'"

echo "evselect table=${indir}/PNclean.fits withspectrumset=yes spectrumset=${outdir}/PN_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression=$exprPNbg" >> products.sh

exprM1bg="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m1bkg}")'"

echo "evselect table=${indir}/M1clean.fits withspectrumset=yes spectrumset=${outdir}/M1_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM1bg" >> products.sh

exprM2bg="'(FLAG==0) && (PATTERN<=12) && ((X,Y) IN "${m2bkg}")'"

echo "evselect table=${indir}/M2clean.fits withspectrumset=yes spectrumset=${outdir}/M2_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=11999 expression=$exprM2bg" >> products.sh

# 3. Calcular el area de las regiones usadas para extraer la fuente y el fondo necesarias para pesar correctamente sus flujos mutuos.

# Para EPIC-pn:
echo "backscale spectrumset=${outdir}/PN_src_spectrum.fits badpixlocation=${indir}/PNclean.fits" >> products.sh
echo "backscale spectrumset=${outdir}/PN_src_bkg_spectrum.fits badpixlocation=${indir}/PNclean.fits" >> products.sh
# Para EPIC-MOS 1:
echo "backscale spectrumset=${outdir}/M1_src_spectrum.fits badpixlocation=${indir}/M1clean.fits" >> products.sh
echo "backscale spectrumset=${outdir}/M1_src_bkg_spectrum.fits badpixlocation=${indir}/M1clean.fits" >> products.sh
# Para EPIC-MOS 2:
echo "backscale spectrumset=${outdir}/M2_src_spectrum.fits badpixlocation=${indir}/M2clean.fits" >> products.sh
echo "backscale spectrumset=${outdir}/M2_src_bkg_spectrum.fits badpixlocation=${indir}/M2clean.fits" >> products.sh

# 4. Usar la tarea rmfgen para crear una matriz de redistribución para el espectro extraído (esto puede llevar más de 30 minutos en computadoras pequeñas):

echo "rmfgen spectrumset=${outdir}/PN_src_spectrum.fits rmfset=${outdir}/PN_src.rmf" >> products.sh
echo "rmfgen spectrumset=${outdir}/M1_src_spectrum.fits rmfset=${outdir}/M1_src.rmf" >> products.sh
echo "rmfgen spectrumset=${outdir}/M2_src_spectrum.fits rmfset=${outdir}/M2_src.rmf" >> products.sh

# 5. Generar la matriz auxiliar. Para fuentes puntuales usar extendedsource=no detmaptype=psf. Para fuentes extendidas usar extendedsource=yes detmaptype=flat o bien generar un mapa de exposición con la tarea expmap).

echo "arfgen spectrumset=${outdir}/PN_src_spectrum.fits arfset=${outdir}/PN_src.arf withrmfset=yes rmfset=${outdir}/PN_src.rmf badpixlocation=${indir}/PNclean.fits extendedsource=no detmaptype=psf" >> products.sh
echo "arfgen spectrumset=${outdir}/M1_src_spectrum.fits arfset=${outdir}/M1_src.arf withrmfset=yes rmfset=${outdir}/M1_src.rmf badpixlocation=${indir}/M1clean.fits extendedsource=no detmaptype=psf" >> products.sh
echo "arfgen spectrumset=${outdir}/M2_src_spectrum.fits arfset=${outdir}/M2_src.arf withrmfset=yes rmfset=${outdir}/M2_src.rmf badpixlocation=${indir}/M2clean.fits extendedsource=no detmaptype=psf" >> products.sh

# 6. Reagrupar el espectro y vincularlo a los archivos asociados tales como el espectro del fondo y las matrices (RMF y ARF). En el ejemplo reagrupamos a un mínimo de 16 cuentas por canal asegurando que el reagrupamiento no exceda un factor 3 en la pérdida de resolución:

echo "specgroup spectrumset=${outdir}/PN_src_spectrum.fits mincounts=16 oversample=3 rmfset=${outdir}/PN_src.rmf arfset=${outdir}/PN_src.arf backgndset=${outdir}/PN_src_bkg_spectrum.fits groupedset=${outdir}/PN_src_grp.fits" >> products.sh
echo "specgroup spectrumset=${outdir}/M1_src_spectrum.fits mincounts=16 oversample=3 rmfset=${outdir}/M1_src.rmf arfset=${outdir}/M1_src.arf backgndset=${outdir}/M1_src_bkg_spectrum.fits groupedset=${outdir}/M1_src_grp.fits" >> products.sh
echo "specgroup spectrumset=${outdir}/M2_src_spectrum.fits mincounts=16 oversample=3 rmfset=${outdir}/M2_src.rmf arfset=${outdir}/M2_src.arf backgndset=${outdir}/M2_src_bkg_spectrum.fits groupedset=${outdir}/M2_src_grp.fits" >> products.sh

chmod +x products.sh

source ./products.sh

rm products.sh

echo -e "\n¡Listo!\n"