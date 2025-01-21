## Introduccion

Este proyecto surge como práctica de la asignatura de visualización de datos.

Siguiendo la metodología y recomendaciones de Moritz Stefaner en un [artículo en Truth & Beauty.net](https://truth-and-beauty.net/appearances/in-the-media/new-challenges-for-data-design)

> The basic set of questions I usually ask are:
> - Why are we doing this?
> - What are you hoping to achieve?
> - Who are we targeting?
> - How is the end product going to be used?
> - How are we publishing?
> - What data do we have available?
> - Which other existing materials should we take into account?
> - Which constraints do we have?
> - Who is responsible for what?
> - Who else is doing something similar?

Todas estas preguntas tienen cabida en cualquier proyecto de visualización, donde a partir de las cuales se desarrolla un proceso iterativo en el que tras cada iteración se replantean, modificando la hoja de ruta del proyecto de ser necesario

![imagen](https://github.com/user-attachments/assets/2a881f25-7699-45b9-8f32-7fe42cb06917)

### Propósito del proyecto

- **¿Porqué estamos haciendo esto?**

Como ya se ha mencionado en la introducción, se trata de una práctica de visualización de datos. El código empleado en realizar la práctica ha de ser publicado en la web y qué mejor que hacerlo en forma de repositorio público. 
De esta forma el código podrá ser reutilizado por quien lo considere necesario y ampliar el alcance del mismo.
  
- **¿Qué esperamos lograr?**

Una infografía que proporcione información relevante sobre el consumo eléctrico en Catalunya.
  
- **¿Quién es nuestro público?**

Cualquier persona interesada en conocer los datos de consumo eléctrico en Catalunya.

- **¿Cómo se usará nuestra visualización?**

La infografía estará disponible públicamente en la web.
  
- **¿Cómo publicaremos?**

Emplearemos una cuenta gratuita de Flourish y publicaremos en [https//public.flourish.studio](https://public.flourish.studio/visualisation/20441699/)
  
- **¿Qué datos tenemos disponibles?**

Datos en abierto del dominio [gencat.cat](https://administraciodigital.gencat.cat/ca/dades/dades-obertes/inici/) publicados por el gobierno autonómico.

Del catálogo de conjuntos de datos disponibles partimos del [Consumo de energía eléctrica por municipios y sectores](https://analisi.transparenciacatalunya.cat/Energia/Consum-d-energia-el-ctrica-per-municipis-i-sectors/8idm-becu/about_data)

- **¿Qué otros materiales deberíamos tener en cuenta?**

Otros dataset del catálogo disponible que tienen relación con el consumo eléctrico:

  [Instalaciones de autoconsumo eléctrico](https://analisi.transparenciacatalunya.cat/Energia/Instal-lacions-d-autoconsum-el-ctric/2b4s-skfm/about_data)
  
  [Instalaciones de producción de energía eléctrica](https://analisi.transparenciacatalunya.cat/Energia/Instal-lacions-de-producci-d-energia-el-ctrica-Dad/arbg-m6sq/about_data)
  
  [Plantas solares fotovoltaicas](https://analisi.transparenciacatalunya.cat/Medi-Ambient/Plantes-solars-fotovoltaiques-a-Catalunya/ggx8-jkp4/about_data)
  
  [Certificados de eficiencia energética de edificios](https://analisi.transparenciacatalunya.cat/Energia/Certificats-d-efici-ncia-energ-tica-d-edificis/j6ii-t3w2/about_data)
  

- **¿Qué restricciones tenemos?**

  - Las impuestas por la guía proporcionada para desarrollar la práctica
    - Relevancia: el conjunto de datos debería ser de actualidad, significativo de interés general, y permite plantear preguntas interesantes.
    - Dimensiones: Del orden de 1000-10000 filas y de 10-100 columnas
    - Características: combina datos numéricos y categóricos
    - Contiene alguna jerarquía: categoría / subcategoría

  - Las impuestas por la herramienta de visualización.
 
    Flourish se basa en el uso de modelos "templates" que se reutilizan proporcionando nuevos datos para una visualización determinada. Deberemos adecuar los datos obtenidos de las fuentes a lo esperado en los modelos previstos.

  - El tiempo.

    Al menos dos iteraciones a realizar antes del 24 de Enero de 2025. (Tempus fugit)  

- **¿Quién es responsable de qué?**

Hasta la fecha de entrega yo, a partir de entonces se aceptan colaboraciones.
  
- **¿Alguien más esta haciendo algo similar?**

Mis compañeros de asignatura, si es que eligieron el mismo cojunto de datos o temática.

### Primera iteración.

Se realiza completamente en R empleando librerías de ggplot. 

### Segunda iteración.

Para poder representar la localización en el mapa los diferentes municipios necesitaremos la longitud y latitud de cada uno de los municipios que obtenemos de

https://analisi.transparenciacatalunya.cat/Urbanisme-infraestructures/Municipis-Catalunya-Geo/9aju-tpwc/about_data

Así como los lolígonos que representan cada uno de los términos municipales o comarcas de cataluña (geoJSSON):

https://catalegs.ide.cat/geonetwork/srv/cat/catalog.search#/metadata/divisions-administratives-v2r1-20240705

Por otro lado para poder calcular el consumo energético por habitante obtenemos los datos del censo municipal:

https://www.ine.es/dynt3/inebase/index.htm?padre=525. 
