library(tidyverse)
library(scales)

comarcas <- read_csv("data/Comarcas-geometry.csv")

# obtenemos los datos de comarcas del fichero de geometrías empleado
# para crear el mapa coroplético
# 
comarcas <- comarcas |>
  select(c('CODICOMAR','NOMCOMAR','CAPCOMAR','AREAC5000')) |>
  mutate(
    Codi_Comarca = str_pad(CODICOMAR, width = 2, pad = '0'),
    Km2 = round(AREAC5000, digits = 2)
  ) |>
  rename(
    Comarca = NOMCOMAR,
    Capital = CAPCOMAR
  ) |>
  select (!c('CODICOMAR','AREAC5000'))

# obtenemos los datos de municipios (Longitud y Latitud)

municipios <- read_csv('data/Municipis_Catalunya_Geo_20250114.csv')

municipios <- municipios |>
  filter(Codi < '999990') |>
  mutate(
    Codi_Municipi = str_sub(Codi, end = 5)
  ) |>
  select(!c(Codi, `UTM X`, `UTM Y`, Georeferència)) |>
  rename(
    Municipi = Nom,
    Codi_Comarca = `Codi comarca`,
    Comarca = `Nom comarca`
  ) |>
  relocate(Codi_Municipi, Municipi)

# Identificamos las capitales de comarca que no podremos establecer su
# Longitud y Latitud mediante la union de comarcas y municipios

comarcas |>
  select(Comarca, Codi_Comarca, Capital) |>
  left_join((municipios |>
               select(Municipi, Codi_Comarca))
            , join_by(Capital == Municipi)) |>
  filter(is.na(`Codi_Comarca.y`))

# Proporcionamos la relacion de las anteriores manualmente
# la co-capitalidad del Vallès Occidental (Sabadell / Terrasa) 
# la geolocalizamos en Sabadell (08178)

capitales <- data_frame(
  Codi_Comarca = c('04','05','10',
                   '12','18','39','40'),
  Codi_Capital = c('25203', '25173', '17022',
                   '43163', '25058', '25243', '08187')) 

# Verificamos que tenemos la relacion de capitales anteriores
comarcas |>
  select(Comarca, Codi_Comarca, Capital) |>
  inner_join(capitales) |>
  inner_join(municipios |>
               select(Municipi, Codi_Municipi, Codi_Comarca),
             join_by(Codi_Capital == Codi_Municipi))

capitales <-
  municipios |>
  filter(Codi_Municipi %in% capitales$Codi_Capital) |>
  bind_rows(
    municipios |>
      filter(Municipi %in% comarcas$Capital)
    ) |>
  rename(
    Codi_Capital = Codi_Municipi,
    Capital = Municipi
  )

#
# Fichero de puntos que cargaremos en los mapas 
#

write_csv(capitales, 'data/capitals_comarcals.csv')

# Cargamos el fichero de geometrías municipales para homogeneizar el codigo
# de municipio (5 dígitos) y obtener la extensión en km2

geometria <- read.csv('data/Municipios-geometry.csv')

# Comprobamos la integridad de los dos conjuntos de datos
# el resultado de la siguiente sentencia deberia ser 0

geometria |>
  select(CODIMUNI, NOMMUNI) |>
  mutate(
    CODIMUNI = str_sub(str_pad(CODIMUNI, width = 6, pad = 0), end = 5)
  ) |>
  rename(
    Codi_Municipi = CODIMUNI
  ) |>
  full_join(municipios) |>
  filter(is.na(NOMMUNI) | is.na(Municipi))

#
# reescribimos el fichero para su recarga en Flourish con los codigos de municipio
# homogeneizados
write_csv(geometria |>
            mutate(
              CODIMUNI = str_sub(str_pad(CODIMUNI, width = 6, pad = 0), end = 5)
            ), 'data/Municipios5-geometry.csv')
#
# recogemos la extension del municipio en km2 y lo añadimos a municipios
#
municipios <- municipios |>
  inner_join(
    geometria |> 
      select(CODIMUNI, AREAM5000) |>
      mutate(
        CODIMUNI = str_sub(str_pad(CODIMUNI, width = 6, pad = 0), end = 5)
      ) |>
      rename(
        Codi_Municipi = CODIMUNI,
        km2 = AREAM5000
      )
  )

#
# NO podemos añadir a comarcas la Provincia
# Las comarcas de la Selva, Berguedà, Osona y Cerdaña
# tienen municipios en más de una provincia
# Se descarta emplearlo como agrupacion en los mapas coropléticos
#
comarcas |>
  inner_join(geometria |>
               select(CODICOMAR, NOMPROV) |>
               unique() |>
               mutate(
                 CODICOMAR = as.character(CODICOMAR)
                 ) |>
               rename(
                 Codi_Comarca = CODICOMAR,
                 Provincia = NOMPROV)
  ) |>
  count(Comarca) |>
  filter(n > 1)

# Cargamos el censo de cada una de las provincias catalanas

carga_censo <- function(fichero, desde, hasta){
  censo <- read_csv2(fichero)

  # Los datos del censo proporcionan la poblacion a 1 de enero
  # por sexo y agregados (Total), así como agregados por provincia.
  # Las provincias identificadas con un codigo de solo dos dígitos
  
  censo <- censo |>
    filter(Sexo == 'Total' & Periodo < hasta & Periodo > desde
           & str_detect(Municipios, "^\\d{5}\\s")
    ) |>
    mutate(
      Codi_Municipi = str_sub(Municipios, end = 5),
      Municipi = str_sub(Municipios, start = 7),
      Any = as.integer(Periodo - 1),
      Habitants = as.integer(Total)
    ) |>
    select(Codi_Municipi, Municipi, Any, Habitants)
  
  censo
}

censo <-    carga_censo('data/2861.csv', 2013, 2024) |>
  bind_rows(carga_censo('data/2870.csv', 2013, 2024)) |>
  bind_rows(carga_censo('data/2878.csv', 2013, 2024)) |>
  bind_rows(carga_censo('data/2900.csv', 2013, 2024))

# verificamos la inexistencia de codigos de municipio
censo |>
  filter(!Codi_Municipi %in% municipios$Codi_Municipi)

#
# Realizamos un plot para ver la evolución del censo municipal
#
censo |>
  group_by(Any) |>
  summarise(Poblacion = trunc(sum(Habitants) / 1000)) |>
  ungroup() |>
  ggplot(aes(x=Any, y=Poblacion)) +
  geom_line(linewidth=1.5) +
  scale_x_continuous(breaks = seq(2013, 2022, by = 1), 
                     limits=c(2013, 2022)) +
  scale_y_continuous(limits = c(0, 8000)) +
  labs(
    title = 'Evolucion del censo municipal en la ultima decada',
    x = 'Año',
    y = 'Miles de habitantes',
    caption = 'Source: https://www.ine.es'
  )

#
# Añadimos a los municipios la poblaciona 1 de Enero de 2023
#
municipios <- municipios |>
  left_join(censo |> 
              filter(Any == 2022) |>
              select(Codi_Municipi, Habitants)
  )

#
# Comprobamos la inexistencia de nans
#
municipios |> 
  filter(is.na(Habitants))

# añadimos al censo el código de comarca para realizar la agregacion y 
# obtener el numero de habitantes comarcales
#
censo <- censo |>
  inner_join(municipios |>
               select(Codi_Municipi, Codi_Comarca))

# la variación de la población ha sido aproximadamente de un 6% en una década
# emplear la variación por año para ajustar el tamaño de las capitales
# no aporta significado. Nos quedamos unicamente con el censo a 1 de Ene de 2023

censo_anual <- censo |>
  group_by(Any)|>
  summarise(
    Poblacion = trunc(sum(Habitants) / 1000)
  )

censo_comarcal <- censo |>
  filter(Any == 2022) |>
  group_by(Codi_Comarca) |>
  summarise(Habitants = sum(Habitants)) |>
  ungroup() 

#
# Fichero de puntos geográficos a utilizar en los mapas de comarcas
#
write_csv(capitales |>
  inner_join(censo_comarcal), 'data/capitals_comarcals.csv')

# Los municipios de las comarcas del Moianès (desde 2015) y del Lluçanès 
# (desde 2023) no están categorizados en dichas comarcas para los años 
# anteriores en el dataset de consumos, por lo que habrá que homogeneizar.
# Tomamos la categorizacion de comarcas de los cojuntos anteriores

consum <- read.csv("data/Consum_d_energia_el_ctrica_per_municipis_i_sectors_de_Catalunya_20241222.csv")

attr(consum, 'names') <- c('Any', 'Provincia', 'Comarca', 
                           'Codi_Municipi', 'Municipi',
                           'Codi_Sector', 'Descripcio_Sector',
                           'Consum_kWh', 'Observacions')

# Salvamos en un dataframe los descriptores de los sectores
# y nos quedamos unicamente con el Año, códigos y consumo en kWh/dia

sectores <- consum |>
  select(Codi_Sector, Descripcio_Sector) |>
  mutate(
    Codi_Sector = as.character(Codi_Sector)
  ) |>
  unique()

# eliminamos nans y calculamos el consumo medio diario

consum <- consum |>
  mutate(
    Any = as.integer(Any),
    Codi_Municipi = str_pad(Codi_Municipi, width = 5, pad = '0'),
    Codi_Sector = as.character(Codi_Sector),
    kWh_dia = Consum_kWh / 365
  ) |>
  select(Any, Codi_Municipi, Codi_Sector, kWh_dia ) |>
  na.omit() 

#
#  csv con los datos de consumo total por año, grafica final de la primera iteracion
#  y con la que introduciremos los mapa coropleticos comarcales
#

write_csv(
  consum |>
    group_by(Any, Codi_Sector) |>
    summarise(    
      MWh_dia = round(sum(kWh_dia) / 1000, digits = 2)
      ) |>
    inner_join(sectores) |>
    select(Any, MWh_dia, Descripcio_Sector) |>
    pivot_wider(
      values_from = MWh_dia,
      names_from = Descripcio_Sector
      ) |>
    inner_join(censo_anual), 'data/consum-anual-sectores.csv')

# comprobamos la NO existencia de GAPS en la codificacion de municipios

consum |>
  filter(!Codi_Municipi %in% municipios$Codi_Municipi)

#
# Funcion para generar la hoja de regiones de consumos comarcales
#

consumo_comarcal <- function(sector, fichero){
  write_csv(
    municipios |>
    select(Codi_Comarca, Codi_Municipi) |>
    inner_join(
      consum |>
        filter(Codi_Sector == sector)
    ) |>
    group_by(Any, Codi_Comarca) |>
    summarise(
      MWh_dia = round(sum(kWh_dia) / 1000, digits = 2)
    ) |>
    ungroup() |>
    pivot_wider(
      names_from = Any,
      values_from = MWh_dia
    ) |>
    inner_join(comarcas) |>
    inner_join(censo_comarcal), fichero)
}

# obtenemos consumos comarcales para diferentes sectores
# y generamos los ficheros csv de regiones a cargar en los mapas

consumo_comarcal(3, 'data/comarcal_industrial.csv')
consumo_comarcal(6, 'data/comarcal_terciario.csv')
consumo_comarcal(5, 'data/comarcal_transporte.csv')
consumo_comarcal(7, 'data/comarcal_doméstico.csv')


#
# Añadimos el consumo por habitante al conjunto inicial
# eso nos permitirá trabajar con la nueva métrica
#
consum <- consum |>
  inner_join(censo |>
               select(Any, Codi_Municipi, Habitants)) |>
  mutate(      
    kWh_dia_hab = round(kWh_dia / Habitants, digits = 2)
  ) 

summary(consum)
#
# funcion para generar csv con los consumos / habitante
# de los municipios
#
consum_habitant <- function(sector, fichero){
  write_csv(
    consum |>
      filter(Codi_Sector == sector) |>
      select(Codi_Municipi, Any, kWh_dia_hab) |>
      arrange(Codi_Municipi, Any) |>
      pivot_wider(
        names_from = Any,
        values_from = kWh_dia_hab
        ) |>
      inner_join(municipios), fichero)
}
  
consum_habitant(7, 'data/municipal_domestico.csv')
consum_habitant(6, 'data/municipal_terciario.csv')

#
# Obtenemos estadísticos para los sectores doméstico y terciario a fin de 
# obtener valores con significado que acompañen al texto de las graficas 
#
consum |>
  filter(Codi_Sector == 7) |>
  group_by(Any) |>
  summarise(
    enframe(quantile(kWh_dia_hab, c(0.25, 0.5, 0.75)), "quantile", "kWh_dia_hab")
    ) |>
  pivot_wider(
    names_from = quantile,
    values_from = kWh_dia_hab
  )

#
#  Realizamos un boxplot de la distribucion de consumos domesticos
#
consum |>
  filter(Codi_Sector == 7) |>
  ggplot(aes(y=kWh_dia_hab)) +
    geom_boxplot(aes(x=as.factor(Any))) +
  labs(
    title = 'Distribución del consumo doméstico por Año',
    subtitle = 'Se observa un gran número de municipios con un consumo por encima de la norma',
    x = 'Año',
    y = 'KWh / dia por habitante',
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )

#
# Y repetimos el ejercicio para el consumo del sector terciario 
#

consum |>
  filter(Codi_Sector == 6) |>
  group_by(Any) |>
  summarise(
    enframe(quantile(kWh_dia_hab, c(0.25, 0.5, 0.75)), "quantile", "kWh_dia_hab")
  ) |>
  pivot_wider(
    names_from = quantile,
    values_from = kWh_dia_hab
  )

consum |>
  filter(Codi_Sector == 6) |>
  ggplot(aes(y=kWh_dia_hab)) +
  geom_boxplot(aes(x=as.factor(Any))) +
  labs(
    title = 'Distribución del consumo terciario por Año',
    subtitle = 'Se observa un gran número de municipios con un consumo por encima de la norma',
    x = 'Año',
    y = 'KWh / dia por habitante',
    caption = 'Source: Institut Català d’Energia (ICAEN) http://dadesobertes.gencat.cat/'
  )


#
# Los cinco municipios con mayor consumo medio en la última década
#

consum |>
  filter(Codi_Sector == 7 ) |>
  group_by(Codi_Municipi) |>
  summarise(
    max = max(kWh_dia_hab, na.rm = TRUE),
    avg = mean(kWh_dia_hab, na.rm = TRUE)
  ) |>
  arrange(desc(avg)) |>
  head(5) |>
  inner_join(municipios) 
  
consum |>
  filter(Codi_Sector == 6 ) |>
  group_by(Codi_Municipi) |>
  summarise(
    max = max(kWh_dia_hab, na.rm = TRUE),
    avg = mean(kWh_dia_hab, na.rm = TRUE)
  ) |>
  arrange(desc(avg)) |>
  head(5) |>
  inner_join(municipios)


consum |>
  filter(Codi_Sector == 7 & kWh_dia_hab > 10) |>
  select(Codi_Municipi) |>
  unique() |>
  count()


consum |>
  filter(Codi_Sector == 6 & kWh_dia_hab > 10) |>
  select(Codi_Municipi) |>
  unique() |>
  count()
  


  
