#Configuration

Il faut mettre dans les variables d'environnement suivantes les user et password de Service Now :

``````
uname=
pwd=
``````
J'ai personnellement créé un script shell pour les positionner avant de démarrer l'appli :

``````
. ./setenv.sh
dashing start
``````

Une fois installé en ayant cloné la repository, il faudra créer un répertoire security avec les fichiers suivants :
* contacts.yml
* nagios.yml
* servicenow.html
* websites.yml
