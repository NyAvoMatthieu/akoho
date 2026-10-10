On va parler gestion de poule pondeuse.
La partie qu'on va aborder ne concerne pas encore la nourriture et le traitement des poules aptes a pondre,seulement leur acheminement a partir du bon de commande jusqu'a la repartition en compartiment. 
Imaginons que je sois une entreprise qui va elever des poules pondeuses ,je commande a un fournisseur tel quantite de poulets( males et femelles - majoritairement) ,j'ai donc un bon de commande avec X poulets. Puis une premiere livraison se fait a l'aeroport ,la je recois un bon de livraison(de reception pour etre exact mais ignorons cet abus de langage) attestant de l'arrivee de ma commande a l'aeroport.La encore je compte le nombre de poulets morts et disparus avant de diriger les poulets restants vers mon poulailler. Une fois arrive,je les compte une fois de plus avant de les repartir dans les compartiments en separant male,femelle et ceux qui sont malades.

a chaque comptage (a chaque livraison en quelque sorte), on saisit:
-date
-bon de livraison(BL) antecedent (ou bon de commande si livraison aeroport) - sachant qu'une fois au poulailler ,on considere le bon de livraison a l'aeroport comme l'antecedent|[liste deroulante]
-le nombre reel arrive(vivants)
-le nombre de poulets morts
-le nombre de poulets perdus (calcule en soustrayant de la quantite theorique le nombre de poulets arrives et morts)
** la quantite theorique est le nombre de poulets dans le bon antecedent,ex:BC : 100 poulets = qtt theorique ; aeoport : arrives = 90,mort=5; poulailler : qtt theorique = 90
-lieu(aeroport ou poulailler)

pour chaque saisie,on verifiera cote metier si le bon existe

une fois au poulailler,on va refaire une saisie similaire a celle mentionnee precedemment,puis le nombre reel va etre reparti dans les compartiments ,la saisie pour les compartiments sera comme suit :
-date
-BL
-plusieurs lignes avec le schema :
.compartiment[liste deroulante]
.qtt(superieur a 0)
.sexe(male/femelle)
.sante(valeur numerique entre et 10)

lors de l'enregistrement de la repartition,on verifiera que la somme des qtt des lignes correspondent au nombre reel de poulets arrives au poulailler

les classes a creer :
-compartiment : id,nom ,capacite,idPoulailler
-magasin(ou lieu) : id,nom
-poulet : id,nom ,race
-controle(pour la saisie sur les lieux): id,date,idBL,idMagasin,nbVivant,nbMort,nbPerdu
-repartition(pour la division vers les compartiments):id,date,idBL,repartition_fille[]
-repartition_fille:id,idRepartitionMere,compartiment,qtt,sexe,sante

Reutiliser les modules de gestion des bons de commandes et bons de livraisons existants(anticiper la liaison avec les modules de factures)

Redige un .md contenant les instructions sur les fichiers a creer (mets y les fichiers pouvant etre utilises comme reference) ,les commandes a executer (s'il y en a),le cheminement des tests(a creer) et autres informations necessaires.  

-- ============================================================================

/* On va parler gestion de poule pondeuse.
La partie qu'on va aborder ne concerne pas encore la nourriture et le traitement des poules aptes a pondre,seulement leur acheminement a partir du bon de commande jusqu'a la repartition en compartiment. 
Imaginons que je sois une entreprise qui va elever des poules pondeuses ,je commande a un fournisseur tel quantite de poulets( males et femelles - majoritairement) ,j'ai donc un bon de commande avec X poulets. Puis une premiere livraison se fait a l'aeroport ,la je recois un bon de livraison(de reception pour etre exact mais ignorons cet abus de langage) attestant de l'arrivee de ma commande a l'aeroport.La encore je compte le nombre de poulets morts et disparus avant de diriger les poulets restants vers mon poulailler. Une fois arrive,je les compte une fois de plus avant de les repartir dans les compartiments en separant male,femelle et ceux qui sont malades. */

Ignore tout ce qu'on a cree jusqu'ici.

Ce projet gere deja tout ce qu'on a decrit ,du bon de commande a la mise en compartiment

Releve toutes les classes existantes et explique le fonctionnement actuel du projet: de la commande a la mise en compartiment 
Mets le tout dans des fichiers .mg en les regroupant par categorie.