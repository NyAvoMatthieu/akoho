-- ============================================================================
-- Diagnostic avant installation du module "acheminement des poules pondeuses"
--
-- A executer sur le schema cible, avant le script d'installation. Ce script ne
-- modifie rien : il se limite a des lectures.
--
--   @2026-10-05-acheminement-poules-pondeuses-diagnostic.sql
--
-- Les 5 questions about, dans l'ordre d'importance pour le script.
-- ============================================================================

SET PAGESIZE 200 LINESIZE 200 FEEDBACK OFF

-- ----------------------------------------------------------------------------
-- Q1. Version d'Oracle
--
-- Oracle 12.2 et ulterieur autorise 128 caracteres pour un identifiant.
-- En dessous, la limite est de 30 caracteres, et un identifiant plus long
-- echoue avec ORA-00972 sans que le CREATE TABLE soit effectue.
-- C'est la cause du premier bloc d'erreurs observe.
-- ----------------------------------------------------------------------------
SELECT banner FROM v$version WHERE ROWNUM = 1;

-- Si vous etes en 12.1 ou inferieur, tous les identifiants du script
-- d'installation tiennent dans 30 caracteres.

-- ----------------------------------------------------------------------------
-- Q2. La table de metadonnees APJ est-elle accessible ?
--
-- C'est la question la plus importante. Le noyau APJ interroge
-- "listeColonneTable" pour savoir quelles colonnes exposer dans les
-- formulaires (decompiled/apj-core/bean/ListeColonneTable, ligne 289).
--
-- Sans cette table, aucune page APJ ne peut fonctionner, pas seulement celles
-- de ce module : c'est une table du socle applicatif.
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS accessible FROM listeColonneTable WHERE ROWNUM = 1;

-- Si vous obtenez ORA-00942, la table n'existe pas sous ce nom dans le schema
-- courant. Passez alors a la question Q3.
-- Si vous obtenez une valeur, le socle est bien present : descendez a Q4.

-- ----------------------------------------------------------------------------
-- Q3. Comment la table de metadonnees est-elle exposee ?
--
-- Le premier essai de dependances avait utilise user_tables et concluait a
-- l'absence de table. LISTECOLONNETABLE s'appelle pourtant comme une table,
-- mais n'en est pas une : c'est une vue. Elle porte aussi un OWNER en colonne 1,
-- qu'elle peut filtrer.
-- ----------------------------------------------------------------------------
SELECT owner, object_name, object_type
  FROM all_objects
 WHERE object_name = 'LISTECOLONNETABLE';

PROMPT === schema connecte ===
SELECT USER AS schema_connecte FROM DUAL;

PROMPT === owners distincts vus par la vue ===
SELECT DISTINCT owner FROM listeColonneTable ORDER BY owner;

-- Si l'OWNER de la vue differe du schema connecte, la vue n'expose pas les
-- tables de ce schema et aucun formulaire APJ ne fonctionnera. Reglez le
-- probleme cote socle applicatif : ce module n'y peut rien.

-- ----------------------------------------------------------------------------
-- Q4. Structure de la table de metadonnees
--
-- Le noyau APJ lit la ligne metadata ainsi :
--
--   SELECT * FROM listeColonneTable
--    WHERE table_Name = upper('<NOM_TABLE>')
--    ORDER BY column_id ASC
--
-- puis utilise la 3e valeur comme nom de champ et la 4e comme type SQL
-- (decompiled/apj-core/bean/ListeColonneTable, ligne 289). Ces positions sont
-- lues sans nommer de colonne : leur numero est donc fige par la definition
-- de la vue, pas par le code Java.
--
-- Si LISTECOLONNETABLE est projetee sur ALL_TAB_COLUMNS, les positions 3 et 4
-- sont COLUMN_NAME et DATA_TYPE, 7 est DATA_LENGTH, 8 DATA_PRECISION et
-- 9 DATA_SCALE. Verifiez que c'est bien le cas.
-- ----------------------------------------------------------------------------
SELECT column_id AS position,
       column_name,
       data_type,
       data_length,
       nullable
  FROM user_tab_columns
 WHERE table_name = 'LISTECOLONNETABLE'
 ORDER BY column_id;

PROMPT === la vue est-elle projetee sur le dictionnaire Oracle ? ===
SELECT COUNT(*) AS colonnes_communes
  FROM user_tab_columns a
  JOIN user_tab_columns b ON b.column_id = a.column_id
                        AND b.column_name = a.column_name
 WHERE a.table_name = 'LISTECOLONNETABLE'
   AND b.table_name = 'ALL_TAB_COLUMNS';

-- Colonnes_communes = 31 (ou 30 sur un dictionnaire plus ancien) confirme que
-- la vue reprend le dictionnaire colonne par colonne : les metadonnees des
-- tables du module y apparaissent des leur creation, sans insertion.

-- Si ce compte est nettement inferieur, la vue n'est pas projetee sur
-- ALL_TAB_COLUMNS : elle a sa propre structure, et les positions 3 et 4 ne
-- sont plus COLUMN_NAME et DATA_TYPE. Relevez le tableau ci-dessus et
-- adaptez les lectures du noyau, cote socle.

-- Q4. Structure de la table de metadonnees
--
-- Le noyau APJ lit la ligne metadata ainsi :
--
--   SELECT * FROM listeColonneTable
--    WHERE table_Name = upper('<NOM_TABLE>')
--    ORDER BY column_id ASC
--
-- puis utilise les colonnes 3 et 4 comme nom de champ et type SQL
-- (bean.Champ), et les colonnes 8 et 9 comme taille et precision.
--
-- Le script d'installation detecte ces colonnes par leur nom. Affichez le
-- schema pour verifier que la detection aboutit.
-- ----------------------------------------------------------------------------
SELECT column_id AS position,
       column_name,
       data_type,
       data_length,
       nullable
  FROM user_tab_columns
 WHERE table_name = 'LISTECOLONNETABLE'
 ORDER BY column_id;

PROMPT === le schema doit-il etre lu via all_tab_columns (table d'un autre schema) ? ===
SELECT column_id AS position,
       column_name,
       data_type,
       data_length,
       nullable
  FROM all_tab_columns
 WHERE table_name = 'LISTECOLONNETABLE'
   AND owner = (SELECT USER FROM DUAL)
 ORDER BY column_id;

-- Repere pour la detection automatique du script :
--   position 3 -> nom de la colonne SQL
--   position 4 -> type SQL
--   position 8 -> taille
--   position 9 -> precision
--
-- Si la position 3 ne contient pas un nom de colonne et la position 4 pas un
-- type, la detection par nom echouera : il faudra adapter la section 6, ou
-- declarer les 4 roles en dur.

-- ----------------------------------------------------------------------------
-- Q5. Tables preexistantes dont depend le module
--
--   BATIMENT : cible des cles etrangeres de MAGASIN_ELEVAGE et COMPARTIMENT
--   SEXE     : alimente la liste deroulante du sexe dans repartition-saisie.jsp
--
-- Des BATIMENT et SEXE existants sous d'autres noms imposent d'adapter les
-- references du script.
-- ----------------------------------------------------------------------------
SELECT table_name FROM user_tables
 WHERE table_name IN ('BATIMENT', 'SEXE')
 ORDER BY table_name;

PROMPT === SEXE doit contenir les valeurs '0' et '1' ===
SELECT id, val FROM sexe ORDER BY id;

PROMPT === BATIMENT doit avoir une colonne ID exploitable ===
SELECT column_name, data_type, data_length
  FROM user_tab_columns
 WHERE table_name = 'BATIMENT'
 ORDER BY column_id;

PROMPT === objets du module deja presents (installation a reinitialiser ?) ===
SELECT object_type, object_name
  FROM user_objects
 WHERE object_name IN ('POULET', 'MAGASIN_ELEVAGE', 'COMPARTIMENT',
                       'CONTROLE_POULET', 'REPARTITION', 'REPARTITION_FILLE',
                       'GETSEQPOULET', 'GETSEQMAGASINELEVAGE',
                       'GETSEQCOMPARTIMENT', 'GETSEQCONTROLEPOULET',
                       'GETSEQREPARTITION', 'GETSEQREPARTITIONFILLE',
                       'SEQ_POULET', 'SEQ_MAGASIN_ELEVAGE',
                       'SEQ_COMPARTIMENT', 'SEQ_CONTROLE_POULET',
                       'SEQ_REPARTITION', 'SEQ_REPART_FILLE',
                       'DISPONIBILITE_LIEU', 'DISPONIBILITE_COMPARTIMENT',
                       'CAPACITE_RESTANTE_COMPARTIMENT', 'SUIVI_ACHEMINEMENT')
 ORDER BY object_type, object_name;

-- Si cette derniere liste renvoie des lignes, executer d'abord
-- 2026-10-05-acheminement-poules-pondeuses-reset.sql, sinon le script
-- d'installation echouera sur ORA-00955 (nom deja utilise).

PROMPT === type des objets GETSEQ : doivent etre des FUNCTION ===
-- Le noyau APJ appelle ces objets par "select <nom> from dual", jamais par
-- "<nom>.nextval". Un objet de type SEQUENCE provoque ORA-00904 a la premiere
-- saisie. Un objet absent produit le meme ORA-00904.
SELECT object_name, object_type
  FROM user_objects
 WHERE object_name IN ('GETSEQPOULET', 'GETSEQMAGASINELEVAGE',
                       'GETSEQCOMPARTIMENT', 'GETSEQCONTROLEPOULET',
                       'GETSEQREPARTITION', 'GETSEQREPARTITIONFILLE')
 ORDER BY object_name;

-- Attendu apres installation : 6 lignes, toutes en FUNCTION.

PROMPT === chaque fonction de compteur repond-elle ? ===
-- Les 6 requetes doivent renvoyer un nombre. Une erreur ici confirme un objet
-- compteur absent, du mauvais type, ou invalide.
SELECT GETSEQPOULET FROM dual;
SELECT GETSEQMAGASINELEVAGE FROM dual;
SELECT GETSEQCOMPARTIMENT FROM dual;
SELECT GETSEQCONTROLEPOULET FROM dual;
SELECT GETSEQREPARTITION FROM dual;
SELECT GETSEQREPARTITIONFILLE FROM dual;

-- Attention : ces appels consomment une valeur. C'est sans consequence sur une
-- installation neuve ; ne pas repeter sur une base deja peuplee si l'on veut
-- conserver une numerotation contigue.