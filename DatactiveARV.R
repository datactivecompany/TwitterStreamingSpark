# DATACTIVE AL ROJO VIVO

#-------------------CARGA DE TWITTER--------------------------

# CARGAMOS LOS PAQUETE STREAMR, PARA CONECTARNOS A LA API DE TWITTER
install.packages("streamR")
library(streamR)

install.packages("ROAuth")
library(ROAuth)

# RUTAS Y CREDENCIALES DE LLAMADA A LA API DE TWITTER
requestURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"

consumerKey <- "XXXXX"
consumerSecret <- "XXXXX"

# ESTABLECEMOS CONEXIÓN
my_oauth <- OAuthFactory$new(consumerKey = consumerKey, 
                             consumerSecret = consumerSecret, 
                             requestURL = requestURL, 
                             accessURL = accessURL, 
                             authURL = authURL)
my_oauth$handshake(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))

# GUARDAMOS LA CONEXIÓN PARA AHORRARNOS EL PASO ANTERIOR
save(my_oauth, file = "my_oauth.Rdata")
load("my_oauth.Rdata")

# BUSCAMOS EN TWITTER FILTRANDO POR HASTAG
vHastags <- c("@DebatAlRojoVivo", "#OperaciónLezoARV"," #OperacionLezoARV","#LaberintoLezoARV","#DimisiónAguirreARV", "DimisionAguirreARV")

file = "tweets_ARV25_4.json"
track = vHastags
follow = NULL
loc = NULL
lang = NULL
minutes = 5
time = 60*minutes
tweets = 20000
filterStream(file.name = file, 
             track = track,
             follow = follow, 
             locations = loc,
             language = lang,
             #timeout = time, 
             tweets = tweets, 
             oauth = my_oauth,
             verbose = TRUE)


#-----------------LIMPIAMOS LOS DATOS--------------------------

# CONVERTIMOS DE TXT CON JSON A DATAFRAME
tweets.df <- parseTweets(file)
save(file="tweetsDF.RDATA", tweets.df)

# AÑADIMOS UNA COLUMNA CON LOS HASTAGS
library(stringr)
tweets.df$hashtags <- str_extract(tweets.df$text, "#[:alnum:]+")

# COGEMOS SOLO LA COLUMNA CON LOS HASTAGHS Y LA DEL TIMESTAMP 
tweets.df.has <- tweets.df[!is.na(tweets.df$hashtags),]
tweets.df.has <- tweets.df.has[,c(43,9)] 

# AÑADIMOS LAS COLUMNAS DE TERTULIANOS
tertulianos.df <- read.csv("tertulianos.csv", sep = ";")

install.packages("qpcR")
library(qpcR)

tweets.df.ht <- qpcR:::cbind.na(tweets.df.has,  tertulianos.df)
tweets.df.ht[is.na(tweets.df.ht)] <- 0

# NOS QUEDAMOS SOLO CON LOS HASTAGS DE LA TEMÁTICA DEL DÍA
tweets.df.ht <- tweets.df.ht[tweets.df.ht$hashtags %in% vHastags,]
twetts.df.tot <-  tweets.df.ht[1,]

# AÑADIMOS LA FECHA Y EL TOTAL DE TWEETS
twetts.df.tot$created_at <- str_sub(twetts.df.tot$created_at,1,10)
twetts.df.tot$NTweets <- nrow(tweets.df.ht)


#------------------MACHINE LEARNING---------------------------

# CARGAMOS Y LIMPIAMOS EL DATASET
tweetsTotal <- read.csv("TweetsTotal.csv", sep = ";")
tweetsTotal <- tweetsTotal[,-2]
str(tweetsTotal)
#tweetsTotal[,2:43] <- lapply(tweetsTotal[,2:43], as.factor)

# DIVIDIMOS EL DATASET EN TRAINING Y TEST SETS
install.packages("caTools")
library(caTools)
split <- sample.split(tweetsTotal$NTweets, SplitRatio = 0.8)
training_set <- subset(tweetsTotal, split == TRUE)
test_set <- subset(tweetsTotal, split == FALSE)

# REGRESION LINEAL MULTIPLE
regressor <- lm(formula = training_set$NTweets ~ .,
                data = training_set[,1:43])
y_pred <- predict(regressor, newdata = test_set[,1:43])

# COMPARAMOS RESULTADOS
y_pred_df <- cbind(original = test_set$NTweets, data.frame(multivariable = round(y_pred)))

summary(regressor)


# RANDOM FORESTS
install.packages("randomForest")
library(randomForest)

regressor2 <- randomForest(x = training_set[,1:43],
                          y = training_set$NTweets,
                          ntree = 100)
y_pred2 <- predict(regressor2, test_set[,1:43])

# COMPARAMOS RESULTADOS
y_pred_df <- cbind(y_pred_df, data.frame(RandomF = round(y_pred2)))

install.packages("miscTools")
library(miscTools)
r2 <- rSquared(test_set$NTweets, test_set$NTweets - predict(regressor2, test_set[,1:43]))
