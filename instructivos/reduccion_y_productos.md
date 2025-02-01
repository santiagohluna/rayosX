# Reducción y análisis de datos de observaciones de XMM Newton

---

A continuación se listan losp pasos a seguir para recalibrar, filtrar y obtener el espectro y curva de luz de una fuente puntual a partir de las observaciones "crudas" de XMM-Newton.

## Reprocesamiento

1. Apuntar la variable `SAS_ODF` a la carpeta donde se encuentran las observaciones, p. ej.:
   `export SAS_ODF=/home/shluna/Proyectos/RX/objetos/rtcru/observaciones/xmm/0831790801`
   Antes de continuar, se debe verificar que la variable `SAS_CCFPATH` esté definida en `.bashrc` apuntando a la carpeta donde se encuantran los archivos de calibración.
2. Luego, ejecutar la tareas `cifbuild`, la cual crea el archivo `cif.ccf`.
3. Apuntar la variable `SAS_CCF` a este último archivo:`export SAS_CCF=cif.ccf`.
4. Ejecutar la tarea `odfingest` para actualizar el archivo de resumen `*SUM.SAS`.
5. Apuntar la variable `SAS_ODF` al archivo de resumen actualizado: `export SAS_ODF=*SUM.SAS`.
6. Por último, ejecutar las tareas `emproc`y `epproc` para reprocesar las observaciones de los detectores EPIC-MOS y EPIC-pn, respectivamente.

## Filtrado de la lista de eventos

Antes de comenzar conviene hacer una copia de seguridad de las listas eventos originales detectados por cada cámara. Estos están guardado en los archivos que finalizan `*Evts.ds`:

- `cp 3522_0831790801_EPN_S003_ImagingEvts.ds PN.fits`
- `cp 3522_0831790801_EMOS1_S001_ImagingEvts.ds M1.fits`
- `cp 3522_0831790801_EMOS2_S002_ImagingEvts.ds M2.fits`

Ahora sí, se comienza con el filtrado:

1. Extraer una curva de luz de eventos singulares (con patrón “0”) a energías por encima de 10 keV para cada cámara (PN, MOS1, MOS2) para identificar los intervalos de alto background, usando la tarea `evselect` de SAS:

    - `evselect table=PN.fits withrateset=Y rateset=ratesPN.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EP && (PI>10000&&PI<12000) && (PATTERN==0)'`
    - `evselect table=M1.fits withrateset=Y rateset=ratesM1.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)'`
    - `evselect table=M2.fits withrateset=Y rateset=ratesM2.fits maketimecolumn=Y timebinsize=100 makeratecolumn=Y expression='#XMMEA_EM && (PI>10000) && (PATTERN==0)'`

La curva de luz resultante puede ser visualizada usando dsplot: `dsplot table=rateEPIC.fits x=TIME y=RATE`

2. Usando la tarea `tabgtigen` se determinan los intervalos de tiempo en los que la curva de luz es baja y constante eligiendo un límite o *threshold* (en cuentas por segundo) para crear el archivo GTI, `EPICgti.fits`:
   
   - `tabgtigen table=ratesPN.fits expression='RATE<=0.4' gtiset=PNgti.fits`
   - `tabgtigen table=ratesM1.fits expression='RATE<=0.35' gtiset=M1gti.fits`
   - `tabgtigen table=ratesM2.fits expression='RATE<=0.35' gtiset=M2gti.fits`

3. Por último, usamos nuevamente `evselect` para generar la lista de eventos filtrada, `EPICclean.fits`:

   - `evselect table=PN.fits withfilteredset=Y filteredset=PNclean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EP && gti(PNgti.fits,TIME) && (PI>150)'`
   - `evselect table=M1.fits withfilteredset=Y filteredset=M1clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M1gti.fits,TIME) && (PI>150)'`
   - `evselect table=M2.fits withfilteredset=Y filteredset=M2clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EM && gti(M2gti.fits,TIME) && (PI>150)'`

## Obtención de la curva de luz

1. En primer lugar, se deben inicializar las variables de entorno `SAS_ODF` y `SAS_CCF`:

   - `export SAS_ODF=/home/shluna/Proyectos/RX/objetos/rtcru/observaciones/xmm/0831790801`
   - `export SAS_CCF=ccf.cif`
2. Abrir las imágenes `PNclean.img`, `M1clean.img` y `M2clean.img` usando `ds9` y seleccionar una región circular entorno a la fuente de la que se pretende generar la curva de luz. Haciendo doble-click sobre la región circular, y eligiendo coordenadas físicas en el despliegue, obtener las coordenadas del centro y el radio:

3. Extraer la curva de luz de la fuente usando la región elegida e incluyendo una selección de eventos de calidad apropiada para la curva de luz y un agrupamiento de, por ejemplo, 5 segundos:

   - `evselect table=PNclean.fits energycolumn=PI expression='(FLAG==0)&& (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN circle(26996.578,24240.85,400.0))' withrateset=yes rateset=PN_src_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes`
   - 
4. Repetir el paso 2 para seleccionar una región con el fondo.
5. Extraer la curva de luz del fondo, usando las mismas expresiones que para la fuente:

   `evselect table=PNclean.fits energycolumn=PI expression='(FLAG==0) && (PATTERN<=4) && (PI in [300:10000]) && ((X,Y) IN circle(25434.659,23330.045,1000.00))' withrateset=yes rateset=PN_bkg_raw.lc timebinsize=5 maketimecolumn=yes makeratecolumn=yes`
6. Estas curvas de luz deben ser corregidas por varios efectos que modifican la eficiencia del detector como el viñeteo, los pixeles malos o calientes, variación de la PSF y eficiencia cuántica, así como efectos de la estabilidad del satélite durante la exposición, como tiempos muertos o GTIs. La tarea `epiclccorr` de SAS realiza todas estas correcciones automáticamente por nosotros. Para ello deben suministrarse tanto la curva de luz de la fuente como la del fondo, así como la lista de eventos original filtrada:

   `epiclccorr srctslist=PN_src_raw.lc eventlist=PNclean.fits outset=PN_lccorr.lc bkgtslist=PN_bkg_raw.lc withbkgset=yes applyabsolutecorrections=yes`
7. La curva de luz resultante puede graficarse con `dsplot`, `fplot` o revisarse con `fv`:

   `dsplot table=PN_lccorr.lc withx=yes x=TIME withy=yes y=RATE`

## Obtención del espectro

Para comenzar, se deben reptetir los pasos 1, 2 y 4 de los que se deben seguir para la obtención de la curva de luz de la fuente y del fondo, así como también la inicialización de las variables de entorno necesarias.

1. Extraer el espectro de la fuente usando las expresiones de selección similares a las usadas para obtener las curvas de luz, y restringiendo los patrones a simples y dobles. Notar el rango de canales utilizados.

   - `evselect table=PNclean.fits withspectrumset=yes spectrumset=PN_src_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle(26996.578,24240.85,400.00))'`

2. Extraer el espectro del fondo:

   - `evselect table=PNclean.fits withspectrumset=yes spectrumset=PN_src_bkg_spectrum.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN circle(25434.659,23330.045,1000.0))'`
3. Calcular el area de las regiones usadas para extraer la fuente y el fondo necesarias para pesar correctamente sus flujos mutuos. Las áreas son introducidas en un campo del header de los espectros denominado `BACKSCAL`:

   - `backscale spectrumset=PN_src_spectrum.fits badpixlocation=PNclean.fits`
   - `backscale spectrumset=PN_src_bkg_spectrum.fits badpixlocation=PNclean.fits`
4. Usar la tarea rmfgen para crear una matriz de redistribución para el espectro extraído (esto puede llevar más de 30 minutos en computadoras pequeñas):

   - `rmfgen spectrumset=PN_src_spectrum.fits rmfset=PN_src.rmf`
5. Generar la matriz auxiliar. Para fuentes puntuales usar extendedsource=no detmaptype=psf. Para fuentes extendidas usar extendedsource=yes detmaptype=flat o bien generar un mapa de exposición con la tarea expmap).

   - `arfgen spectrumset=PN_src_spectrum.fits arfset=PN_src.arf withrmfset=yes rmfset=PN_src.rmf badpixlocation=PNclean.fits extendedsource=no detmaptype=psf`
6. Reagrupar el espectro y vincularlo a los archivos asociados tales como el espectro del fondo y las matrices (RMF y ARF). En el ejemplo reagrupamos a un mínimo de 16 cuentas por canal asegurando que el reagrupamiento no exceda un factor 3 en la pérdida de resolución:

   - `specgroup spectrumset=PN_src_spectrum.fits mincounts=16 oversample=3 rmfset=PN_src.rmf arfset=PN_src.arf backgndset=PN_src_bkg_spectrum.fits groupedset=PN_src_grp.fits`
  
[Volver al menú principal](../README.md)