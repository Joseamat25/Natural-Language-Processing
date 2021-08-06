###                               RUTAS                                     ####
path_root <- 'N:/UDMTD/UDMTD08/José Alberto Mata - TM on Paradata'
#path_root <- 'C:/Users/David/Documents/Cursos.Seminarios/UCM/TFG/José Alberto Mata - TM on Paradata'
path_data    <- 'C:/Users/arlos/Desktop/TFG/codigos'
path_scripts <- file.path(path_root,'code/scripts')
path_src     <- file.path(path_root, 'code/src')

###                         PAQUETES Y FUNCIONES                            ####
library(readxl)
library(xlsx)
library(openxlsx)
library(data.table)
library(tidytext)
library(magrittr)
library(hash)
library(corpus)
library(ranger)
library(pROC)
library(ggplot2)
library(wordcloud)
###                               FUNCION HASH                              ####

hash <- function(string, modulo, algorithm = 'murmur32'){
  
  hash_hex <- sapply(string, digest::digest, algo = algorithm, serialize = FALSE)
  hash_dec <- Rmpfr::mpfr(hash_hex, base = 16)
  feature  <- as.numeric(hash_dec %% modulo)
  return(feature)
}

###                               PARAMETROS                                ####
hash_modulo <- 10000

###                              LECTURA                                    ####
#datos_originales.dt <- as.data.table(read.xlsx(file.path(path_data, "Datos_ICN_NLP.xlsx")))

setwd("C:/Users/arlos/Desktop/TFG/codigos")
getwd()
datos_originales.dt <- read_excel("Datos_ICN_NLP.xlsx")
datos_originales.dt <- as.data.table(datos_originales.dt)  

###                              PREPROCESAMIENTO                           ####
stopwords_custom <- unique(c(
  tm::stopwords("spanish")[1:21], 
  'este', 'esta', 'esto', 'estos', 'estas',
  'ese', 'esa', 'eso', 'esos', 'esas',
  'un', 'uno', 'una', 'unos', 'unas',
  'hay', 'ha', 'han', 'he', 'hemos', 'es', 'son', 'puede', 'pueden', 'esta', 'estan', 'tiene', 'tienen',
  'me', 'nos', 'le', 'les', 'lo', 'los', 'su', 'sus',
  'el', 'ella', 'ello', 'ellos', 'ellas', 
  'yo', 'tu', 'nos', 'nosotros', 'vosotros',
  'al', 'del', 
  'a', 'ante', 'cabe', 'con', 'de', 'desde', 'en', 'entre', 'hasta', 'para', 'por', 'segun',
  'que', 
  letters))
datos.dt <- data.table::copy(datos_originales.dt)[
  , observa_ume_processed    := tolower(observa_ume_processed)][
  , observa_depura_processed := tolower(observa_depura_processed)]
for (stwrd in stopwords_custom){
  
  cat(paste0(stwrd, '\n'))
  stwrd_pattern <- paste0('( ', stwrd, ' )', '|', '(^', stwrd, ' )', '|', '( ', stwrd, '$)')
  datos.dt <- datos.dt[, observa_ume_processed := gsub(stwrd_pattern, ' ', observa_ume_processed)]
}

datePattrn_num  <- '(0?[1-9]|[12][0-9]|3[01])[/-](0?[1-9]|1[012])([/-](\\d{4}|\\d{2}))?'
datePattrn_char <- 
'(([Ee]ne(ro)?|[Ff]eb(rero)?|[Mm]ar(zo)?|[Aa]br(il)?|[Mm]ayo|[Jj]un(io)?|[Jj]ul(io)?|[Aa]go(sto)?|[Ss]e[p]?(tiembre)?|[Oo]ct(ubre)?|[Nn]ov(iembre)?|[Dd]ic(iembre)?)( ))|
(( )([Ee]ne(ro)?|[Ff]eb(rero)?|[Mm]ar(zo)?|[Aa]br(il)?|[Mm]ayo|[Jj]un(io)?|[Jj]ul(io)?|[Aa]go(sto)?|[Ss]e[p]?(tiembre)?|[Oo]ct(ubre)?|[Nn]ov(iembre)?|[Dd]ic(iembre)?))|
(( )([Ee]ne(ro)?|[Ff]eb(rero)?|[Mm]ar(zo)?|[Aa]br(il)?|[Mm]ayo|[Jj]un(io)?|[Jj]ul(io)?|[Aa]go(sto)?|[Ss]e[p]?(tiembre)?|[Oo]ct(ubre)?|[Nn]ov(iembre)?|[Dd]ic(iembre)?)( ))|
(( )([Ee]ne(ro)?|[Ff]eb(rero)?|[Mm]ar(zo)?|[Aa]br(il)?|[Mm]ayo|[Jj]un(io)?|[Jj]ul(io)?|[Aa]go(sto)?|[Ss]e[p]?(tiembre)?|[Oo]ct(ubre)?|[Nn]ov(iembre)?|[Dd]ic(iembre)?)([-/ ])?(\\d{4}|\\d{2})?)'
datos.dt[
  is.na(observa_ume_processed), observa_ume_processed := ''][
  is.na(observa_depura_processed), observa_depura_processed := ''][
  , observa_ume_processed := chartr('áéíóúÁÉÍÓÚ', 'aeiouAEIOU', observa_ume_processed)][ 
  , observa_ume_processed := chartr('àèìòùÀÈÌÒÙ', 'aeiouAEIOU', observa_ume_processed)][  
  , observa_ume_processed := chartr('äëïöüÄËÏÖÜ', 'aeiouAEIOU', observa_ume_processed)][
  , observa_ume_processed := chartr('âêîôûÂÊÎÔÛ', 'aeiouAEIOU', observa_ume_processed)][
  , observa_ume_processed := gsub("[\\'’]", "", observa_ume_processed)][
  , observa_ume_processed := gsub('(?![-/])[[:punct:]]', ' ', observa_ume_processed, perl = TRUE)][
  , observa_ume_processed := gsub("ç", "c", observa_ume_processed)][  
  , observa_ume_processed := gsub('ñ', 'nh', observa_ume_processed)][
  , observa_ume_processed := gsub(datePattrn_num,
                                  ' undisclosed_date ',
                                  observa_ume_processed)][
  , observa_ume_processed := gsub(datePattrn_char,
                                  ' undisclosed_date ',
                                  observa_ume_processed)][
  , observa_ume_processed := gsub('20[0-2][0-9]',
                                  ' undisclosed_date ',
                                  observa_ume_processed)][
  , observa_ume_processed := gsub('[0-9]+', ' number ', observa_ume_processed)][                                  
  , observa_ume_processed := gsub('undisclosed[_]?',
                                  '',
                                   observa_ume_processed)][
  , observa_ume_processed := gsub(' cif ', ' nif ', observa_ume_processed)]
    
  
nombres_propios.dt <- fread(file.path(path_data, 'nombres_propios_es.txt'), encoding = 'UTF-8', header = FALSE)
setnames(nombres_propios.dt, 'nombre')
nombres_propios.dt[
  , nombre := tolower(nombre)][
  , nombre := chartr('áéíóúÁÉÍÓÚ', 'aeiouAEIOU', nombre)]

for (nombre in nombres_propios.dt$nombre){
  
  cat(paste0(nombre, '\n'))
  nombre_pattern <- paste0('( ', nombre, ' )', '|', '(^', nombre, ' )', '|', '( ', nombre, '$)')
  datos.dt <- datos.dt[
    , observa_ume_processed := gsub(nombre_pattern, 
                                    ' nombre_propio ', 
                                    observa_ume_processed)]
}

for (stwrd in stopwords_custom){

 cat(paste0(stwrd, '\n'))
 stwrd_pattern <- paste0('( ', stwrd, ' )', '|', '(^', stwrd, ' )', '|', '( ', stwrd, '$)')
 datos.dt <- datos.dt[
   , observa_ume_processed := gsub(stwrd_pattern,
                                   ' ',
                                   observa_ume_processed)]
}

size_ngram <- 1
terms.list <- lapply(size_ngram, function(n){
  
  output <- datos.dt %>%
  unnest_ngrams(term, observa_ume_processed, n)
  output <- output[, .(numidest, cambio, cnae, term)]
  return(output)
  
})

terms.list <- lapply(terms.list, function(DT){
  output <- DT[
  , stem := unlist(
    lapply(
      text_tokens(term, 
                  text_filter(stemmer = 'spanish', 
                              stem_except = c('date', 'number', 'nombre_propio', 'iria'))),
      paste, collapse = ' '))
  ]
  return(output)
})


terms_N.dt <- terms.list[[1]][, list(N_term = .N), by = 'term'][order(-N_term)]
wordcloud(terms_N.dt$term[-(1:4)], terms_N.dt$N_term[-(1:4)], max.words = 200, colors = "red")
ggplot(terms_N.dt[5:50], aes(reorder(term, N_term, sum), N_term)) +
  geom_col() +
  coord_flip() +
  labs(x = 'Frecuencia Absoluta', y = 'Término') +
  theme_bw() +
  theme(axis.text=element_text(size=7),
        axis.title=element_text(size=14,face="bold"))

terms_N_numidest.dt <- terms.list[[1]][, list(N_term = .N), by = c('numidest', 'term')][order(-N_term)]
term_tf_idf.dt <- bind_tf_idf(terms_N_numidest.dt, term, numidest, N_term)[order(-tf_idf)]
ggplot(term_tf_idf.dt[1:100], aes(reorder(term, tf_idf, sum), tf_idf)) +
  geom_col() +
  coord_flip() +
  labs(x = 'tf_idf', y = 'Término') +
  theme_bw() +
  theme(axis.text=element_text(size=7),
        axis.title=element_text(size=14,face="bold"))



stems_N.dt <- terms.list[[1]][, list(N_stem = .N), by = 'stem'][order(-N_stem)]
wordcloud(stems_N.dt$stem[-(1:4)], stems_N.dt$N_stem[-(1:4)], max.words = 200, colors = "red")
ggplot(stems_N.dt[5:50], aes(reorder(stem, N_stem, sum), N_stem)) +
  geom_col() +
  coord_flip() +
  labs(x = 'Frecuencia Absoluta', y = 'Raíz') +
  theme_bw() +
  theme(axis.text=element_text(size=7),
        axis.title=element_text(size=14,face="bold"))

stems_N_numidest.dt <- terms.list[[1]][, list(N_stem = .N), by = c('numidest', 'stem')][order(-N_stem)]
stem_tf_idf.dt <- bind_tf_idf(stems_N_numidest.dt, stem, numidest, N_stem)[order(-tf_idf)]
ggplot(stem_tf_idf.dt[1:100], aes(reorder(stem, tf_idf, sum), tf_idf)) +
  geom_col() +
  coord_flip() +
  labs(x = 'tf_idf', y = 'Término') +
  theme_bw() +
  theme(axis.text=element_text(size=7),
        axis.title=element_text(size=14,face="bold"))



features_hash.dt.list <- lapply(terms.list, function(DT){
  
  hash.dt <- DT[
    , hash_value_term := hash(term, hash_modulo)][
    , hash_value_stem := hash(stem, hash_modulo)]
  temp1.dt <- hash.dt[, list(hash_freq_term = .N), by = c('numidest', 'cambio', 'cnae', 'hash_value_term')]
  hash_features_term.dt <- dcast(
    temp1.dt, numidest + cambio + cnae ~ hash_value_term, value.var = 'hash_freq_term')
  name_features <- setdiff(names(hash_features_term.dt), c('numidest', 'cambio', 'cnae'))
  setnames(hash_features_term.dt, name_features, paste0('hash_term', name_features))
  name_features_complete <- paste0('hash_term', 1:hash_modulo)
  name_features_missing  <- setdiff(name_features_complete, names(hash_features_term.dt))
  hash_features_term.dt[
    , (name_features_missing) := NA_character_]
  
  temp2.dt <- hash.dt[, list(hash_freq_stem = .N), by = c('numidest', 'cambio', 'cnae', 'hash_value_stem')]
  hash_features_stem.dt <- dcast(
    temp2.dt, numidest + cambio + cnae ~ hash_value_stem, value.var = 'hash_freq_stem')
  name_features <- setdiff(names(hash_features_stem.dt), c('numidest', 'cambio', 'cnae'))
  setnames(hash_features_stem.dt, name_features, paste0('hash_stem', name_features))
  name_features_complete <- paste0('hash_stem', 1:hash_modulo)
  name_features_missing  <- setdiff(name_features_complete, names(hash_features_stem.dt))
  hash_features_stem.dt[
    , (name_features_missing) := NA_character_]
  
  out <- merge(hash_features_term.dt, hash_features_stem.dt, by = c('numidest', 'cambio', 'cnae'))
  for (j in seq_len(ncol(out))){
    
    set(out, which(is.na(out[[j]])), j, 0)
    
  }
  
  return(out)
})

gc()

hash_features_term.dt <- data.table::copy(features_hash.dt.list[[1]])[
  , numidest := NULL][
  , cambio   := factor(cambio)][
  , c('cambio', 'cnae', paste0('hash_term', 1:hash_modulo)), with = FALSE]
term_rf <- ranger::ranger(
  formula = cambio ~ .,
  data = hash_features_term.dt, 
  num.trees = 150,
  probability = TRUE)
probs_term <- term_rf$predictions[, 1]
roc_term <- roc(hash_features_term.dt$cambio, probs_term)
auc_term <- auc(roc_term)
ggroc(roc_term) +
  annotate("text", x = 0.25, y = 0.25, label = paste0("AUC= ", round(auc_term, 4))) +
  theme_bw()


hash_features_stem.dt <- data.table::copy(features_hash.dt.list[[1]])[
  , numidest := NULL][
  , cambio   := factor(cambio)][
  , c('cambio', 'cnae', paste0('hash_stem', 1:hash_modulo)), with = FALSE]
stem_rf <- ranger::ranger(
  formula = cambio ~ .,
  data = hash_features_stem.dt, 
  num.trees = 150,
  probability = TRUE)
probs_stem <- stem_rf$predictions[, 1]
roc_stem <- roc(hash_features_stem.dt$cambio, probs_stem)
auc_stem <- auc(roc_stem)
ggroc(roc_stem) +
  annotate("text", x = 0.25, y = 0.25, label = paste0("AUC= ", round(auc_stem, 4))) +
  theme_bw()



