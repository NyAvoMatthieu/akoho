-- ============================================================================
-- Acheminement et repartition des poules pondeuses
-- Ref : MD/GUIDE_GESTION_POULES_PONDEUSES.md
--       MD/GUIDE_NAVIGATION_TEST_POULES_PONDEUSES.md
--
-- A executer une seule fois, dans l'ordre des sections.
--
-- Dependances a verifier avant execution (section 0) :
--   - BATIMENT (ID) : cible des cles etrangeres de MAGASIN_ELEVAGE et
--     COMPARTIMENT. Table preexistante, heritee de la configuration ferme.
--   - SEXE (ID, VAL) : alimente la liste deroulante du sexe dans
--     repartition-saisie.jsp. Table preexistante.
--   - LISTECOLONNETABLE : metadonnees APJ, sans quoi les formulaires sont
--     vides et les pages de saisie echouent.
--
-- Les 6 tables creees ici utilisent des noms generiques (POULET,
-- COMPARTIMENT). Verifiez qu'elles n'existent pas deja :
--   SELECT table_name FROM user_tables
--    WHERE table_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                         'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE');
-- Si cette requete renvoie des lignes, ce script a deja ete execute ou une
-- table homonyme existe : dans ce cas ne pas relancer, la section 9 permet
-- de repartir d'une installation propre.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Controle prealable des dependances
--
-- Le test se fait par sonde directe et non via user_tables : un objet peut
-- etre accessible par un synonymme ou appartenir a un autre schema, auquel cas
-- user_tables ne le voit pas alors que le noyau APJ y accede tres bien.
--
-- BATIMENT et SEXE sont des tables : une dependance manquante invalide une
-- cle etrangere du DDL ou prive une liste deroulante, donc le script
-- s'arrete.
--
-- LISTECOLONNETABLE, elle, est une VUE projetee sur le dictionnaire de donnees
-- (voir section 6). Elle ne peut pas disparaitre sans que tout le socle APJ
-- tombe, et aucune de ses lignes n'a besoin d'etre chargee : les metadonnees
-- des tables du module y apparaissent seules. Son absence n'empeche donc pas
-- l'installation, elle est seulement signalee.
-- ----------------------------------------------------------------------------
DECLARE
    v_msg VARCHAR2(4000);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'SELECT 1 FROM BATIMENT WHERE ROWNUM = 1';
    EXCEPTION WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000,
            'La table BATIMENT est inaccessible. Elle est ciblee par les cles '
            || 'etrangeres de MAGASIN_ELEVAGE et COMPARTIMENT. Verifiez le '
            || 'schema auquel vous etes connecte.');
    END;

    BEGIN
        EXECUTE IMMEDIATE 'SELECT 1 FROM SEXE WHERE ROWNUM = 1';
    EXCEPTION WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001,
            'La table SEXE est inaccessible. Elle alimente la liste deroulante '
            || 'du sexe dans repartition-saisie.jsp.');
    END;

    BEGIN
        EXECUTE IMMEDIATE 'SELECT 1 FROM listeColonneTable WHERE ROWNUM = 1';
    EXCEPTION WHEN OTHERS THEN
        v_msg := '[avertissement] la vue listeColonneTable du socle APJ '
              || 'n''est pas accessible depuis ce schema.';
        DBMS_OUTPUT.PUT_LINE(v_msg);
        DBMS_OUTPUT.PUT_LINE(
            '  Les tables, fonctions, sequences, index et vues de ce script '
            || 'seront');
        DBMS_OUTPUT.PUT_LINE(
            '  mais aucun formulaire APJ ne fonctionnera tant que les '
            || 'metadonnees');
        DBMS_OUTPUT.PUT_LINE(
            '  ne seront pas chargees. Executez le script de diagnostic pour '
            || 'connaitre');
        DBMS_OUTPUT.PUT_LINE(
            '  le nom reel de la table de metadonnees du noyau APJ, puis '
            || 'adaptez la section 6.');
    END;
END;
/

SHOW ERRORS

-- Si SHOW ERRORS signale une erreur de compilation, ne pas poursuivre : le
-- controle prealable des dependances n'a pas joue son role.

-- ----------------------------------------------------------------------------
-- 1. Referentiel POULET (categorie / race)
-- ----------------------------------------------------------------------------
CREATE TABLE POULET (
    ID      VARCHAR2(20)  NOT NULL,
    NOM     VARCHAR2(100) NOT NULL,
    RACE    VARCHAR2(100)
);

ALTER TABLE POULET
    ADD CONSTRAINT PK_POULET PRIMARY KEY (ID);

ALTER TABLE POULET
    ADD CONSTRAINT UQ_POULET_NOM UNIQUE (NOM);

-- POULET : compteur d'identifiants.
--
-- ATTENTION : le noyau APJ n'appelle pas une SEQUENCE mais une FONCTION.
-- ClassMAPTable.makePK -> Utilitaire.getMaxSeq construit, pour Oracle,
--     select <nom> from dual
-- Une sequence portant ce nom ne convient pas : ORA-00904. Il faut donc une
-- fonction sans parametre qui encapsule la sequence.
CREATE SEQUENCE SEQ_POULET START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE FUNCTION GETSEQPOULET RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT SEQ_POULET.NEXTVAL INTO v_next FROM dual;
    RETURN v_next;
END;
/
SHOW ERRORS

-- Les metadonnees APJ de POULET sont inserees en section 6, avec les autres
-- tables, a partir de USER_TAB_COLUMNS. Ne pas les declarer ici.

COMMIT;

-- ----------------------------------------------------------------------------
-- 2. Referentiel des lieux (aeroport / poulailler)
-- ----------------------------------------------------------------------------
CREATE TABLE MAGASIN_ELEVAGE (
    ID          VARCHAR2(20)  NOT NULL,
    NOM         VARCHAR2(100) NOT NULL,
    TYPELIEU    VARCHAR2(20)  NOT NULL,
    IDBATIMENT  VARCHAR2(20),
    ACTIF       NUMBER(1)     DEFAULT 1 NOT NULL,
    CONSTRAINT CK_MAGASIN_ELEVAGE_TYPELIEU
        CHECK (TYPELIEU IN ('AEROPORT', 'POULAILLER')),
    CONSTRAINT CK_MAGASIN_ELEVAGE_POULAILLER
        CHECK (TYPELIEU <> 'POULAILLER' OR IDBATIMENT IS NOT NULL)
);

ALTER TABLE MAGASIN_ELEVAGE
    ADD CONSTRAINT PK_MAGASIN_ELEVAGE PRIMARY KEY (ID);

ALTER TABLE MAGASIN_ELEVAGE
    ADD CONSTRAINT UQ_MAGASIN_ELEVAGE_NOM UNIQUE (NOM);

ALTER TABLE MAGASIN_ELEVAGE
    ADD CONSTRAINT FK_MAGASIN_ELEVAGE_BATIMENT
        FOREIGN KEY (IDBATIMENT) REFERENCES BATIMENT (ID);

CREATE SEQUENCE SEQ_MAGASIN_ELEVAGE START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE FUNCTION GETSEQMAGASINELEVAGE RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT SEQ_MAGASIN_ELEVAGE.NEXTVAL INTO v_next FROM dual;
    RETURN v_next;
END;
/
SHOW ERRORS

CREATE INDEX IDX_MLE_BATIMENT ON MAGASIN_ELEVAGE (IDBATIMENT);
CREATE INDEX IDX_MLE_TYPELIEU ON MAGASIN_ELEVAGE (TYPELIEU);

COMMIT;

-- ----------------------------------------------------------------------------
-- 3. Referentiel COMPARTIMENT (un compartiment appartient a un poulailler)
-- ----------------------------------------------------------------------------
CREATE TABLE COMPARTIMENT (
    ID            VARCHAR2(20) NOT NULL,
    NOM           VARCHAR2(100) NOT NULL,
    CAPACITE      NUMBER(10) NOT NULL,
    IDPOULAILLER  VARCHAR2(20) NOT NULL,
    CONSTRAINT CK_COMPARTIMENT_CAPACITE CHECK (CAPACITE > 0)
);

ALTER TABLE COMPARTIMENT
    ADD CONSTRAINT PK_COMPARTIMENT PRIMARY KEY (ID);

ALTER TABLE COMPARTIMENT
    ADD CONSTRAINT FK_COMPARTIMENT_BATIMENT
        FOREIGN KEY (IDPOULAILLER) REFERENCES BATIMENT (ID);

CREATE SEQUENCE SEQ_COMPARTIMENT START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE FUNCTION GETSEQCOMPARTIMENT RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT SEQ_COMPARTIMENT.NEXTVAL INTO v_next FROM dual;
    RETURN v_next;
END;
/
SHOW ERRORS

CREATE INDEX IDX_CMP_POULAILLER ON COMPARTIMENT (IDPOULAILLER);

COMMIT;

-- ----------------------------------------------------------------------------
-- 4. CONTROLE_POULET
--    BC  -> BL -> CONTROLE (aeroport) -> CONTROLE (poulailler) -> REPARTITION
-- ----------------------------------------------------------------------------
CREATE TABLE CONTROLE_POULET (
    ID                   VARCHAR2(20)  NOT NULL,
    DATY                 DATE           NOT NULL,
    TYPEANTECEDENT       VARCHAR2(20)  NOT NULL,
    IDANTECEDENT         VARCHAR2(20)  NOT NULL,
    IDLIGNEANTECEDENT    VARCHAR2(20),
    IDPOULET             VARCHAR2(20)  NOT NULL,
    IDMAGASIN            VARCHAR2(20)  NOT NULL,
    QUANTITETHEORIQUE    NUMBER(10)    DEFAULT 0 NOT NULL,
    NBVIVANT             NUMBER(10)    DEFAULT 0 NOT NULL,
    NBMORT               NUMBER(10)    DEFAULT 0 NOT NULL,
    NBPERDU              NUMBER(10)    DEFAULT 0 NOT NULL,
    ETAT                 NUMBER(3)     DEFAULT 0,
    CONSTRAINT CK_CPL_TYPE_ANTE
        CHECK (TYPEANTECEDENT IN ('BC', 'BL', 'CONTROLE')),
    CONSTRAINT CK_CONTROLE_POULET_NB
        CHECK (NBVIVANT >= 0 AND NBMORT >= 0 AND NBPERDU >= 0 AND QUANTITETHEORIQUE >= 0),
    CONSTRAINT CK_CONTROLE_POULET_EQUILIBRE
        CHECK (NBVIVANT + NBMORT + NBPERDU = QUANTITETHEORIQUE)
);

ALTER TABLE CONTROLE_POULET
    ADD CONSTRAINT PK_CONTROLE_POULET PRIMARY KEY (ID);

ALTER TABLE CONTROLE_POULET
    ADD CONSTRAINT FK_CONTROLE_POULET_POULET
        FOREIGN KEY (IDPOULET) REFERENCES POULET (ID);

ALTER TABLE CONTROLE_POULET
    ADD CONSTRAINT FK_CONTROLE_POULET_LIEU
        FOREIGN KEY (IDMAGASIN) REFERENCES MAGASIN_ELEVAGE (ID);

CREATE SEQUENCE SEQ_CONTROLE_POULET START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE FUNCTION GETSEQCONTROLEPOULET RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT SEQ_CONTROLE_POULET.NEXTVAL INTO v_next FROM dual;
    RETURN v_next;
END;
/
SHOW ERRORS

CREATE INDEX IDX_CPL_ANTECEDENT ON CONTROLE_POULET (IDANTECEDENT);
CREATE INDEX IDX_CPL_LIGNE_ANTECEDENT ON CONTROLE_POULET (IDLIGNEANTECEDENT);
CREATE INDEX IDX_CPL_MAGASIN ON CONTROLE_POULET (IDMAGASIN);
CREATE INDEX IDX_CPL_POULET ON CONTROLE_POULET (IDPOULET);
CREATE INDEX IDX_CPL_DATY ON CONTROLE_POULET (DATY);

COMMIT;

-- ----------------------------------------------------------------------------
-- 5. REPARTITION (maitre) / REPARTITION_FILLE (detail)
-- ----------------------------------------------------------------------------
CREATE TABLE REPARTITION (
    ID                    VARCHAR2(20) NOT NULL,
    DATY                  DATE         NOT NULL,
    IDCONTROLEPOULAILLER  VARCHAR2(20) NOT NULL,
    IDBL                  VARCHAR2(20),
    ETAT                  NUMBER(3)    DEFAULT 0
);

ALTER TABLE REPARTITION
    ADD CONSTRAINT PK_REPARTITION PRIMARY KEY (ID);

ALTER TABLE REPARTITION
    ADD CONSTRAINT FK_REPARTITION_CONTROLE
        FOREIGN KEY (IDCONTROLEPOULAILLER) REFERENCES CONTROLE_POULET (ID);

CREATE SEQUENCE SEQ_REPARTITION START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE FUNCTION GETSEQREPARTITION RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT SEQ_REPARTITION.NEXTVAL INTO v_next FROM dual;
    RETURN v_next;
END;
/
SHOW ERRORS

CREATE INDEX IDX_REP_CONTROLE ON REPARTITION (IDCONTROLEPOULAILLER);
CREATE INDEX IDX_REP_BL ON REPARTITION (IDBL);

CREATE TABLE REPARTITION_FILLE (
    ID                 VARCHAR2(20) NOT NULL,
    IDREPARTITIONMERE  VARCHAR2(20) NOT NULL,
    IDCOMPARTIMENT     VARCHAR2(20) NOT NULL,
    QTT                NUMBER(10)   NOT NULL,
    SEXE               VARCHAR2(1)   NOT NULL,
    SANTE              NUMBER(2)    NOT NULL,
    CONSTRAINT CK_REPARTITION_FILLE_QTT CHECK (QTT > 0),
    CONSTRAINT CK_REPARTITION_FILLE_SEXE CHECK (SEXE IN ('0', '1')),
    CONSTRAINT CK_REPARTITION_FILLE_SANTE CHECK (SANTE BETWEEN 0 AND 10)
);

ALTER TABLE REPARTITION_FILLE
    ADD CONSTRAINT PK_REPARTITION_FILLE PRIMARY KEY (ID);

ALTER TABLE REPARTITION_FILLE
    ADD CONSTRAINT FK_REPARTITION_FILLE_MERE
        FOREIGN KEY (IDREPARTITIONMERE) REFERENCES REPARTITION (ID);

ALTER TABLE REPARTITION_FILLE
    ADD CONSTRAINT FK_RPF_COMPARTIMENT
        FOREIGN KEY (IDCOMPARTIMENT) REFERENCES COMPARTIMENT (ID);

CREATE SEQUENCE SEQ_REPART_FILLE START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE FUNCTION GETSEQREPARTITIONFILLE RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT SEQ_REPART_FILLE.NEXTVAL INTO v_next FROM dual;
    RETURN v_next;
END;
/
SHOW ERRORS

CREATE INDEX IDX_RPF_MERE ON REPARTITION_FILLE (IDREPARTITIONMERE);
CREATE INDEX IDX_RPF_COMPARTIMENT ON REPARTITION_FILLE (IDCOMPARTIMENT);

COMMIT;

-- ----------------------------------------------------------------------------
-- 6. Metadonnees APJ : VERIFICATION UNIQUEMENT, AUCUNE INSERTION
--
-- La table de metadonnees du noyau APJ s'appelle LISTECOLONNETABLE, mais ce
-- n'est pas une table : c'est une VUE exposee par le socle applicatif, projetee
-- sur le dictionnaire de donnees d'Oracle.
--
-- Deux observations le prouvent, et elles sont determinantes pour ce script.
--
-- 1. Interrogee via ALL_OBJECTS, elle ressort avec OBJECT_TYPE = 'VIEW'. Une
--    recherche dans USER_TABLES ne pouvait donc pas la trouver. C'est
--    exactement l'origine du faux "dependance manquante" signale par un ancien
--    controle de ce script.
--
-- 2. Interrogee via USER_TAB_COLUMNS, elle expose 31 colonnes dont la
--    disposition est celle de ALL_TAB_COLUMNS a l'identique :
--
--        position  3 = COLUMN_NAME
--        position  4 = DATA_TYPE
--        position  8 = DATA_PRECISION
--        position  9 = DATA_SCALE
--
--    Or le noyau APJ lit ces memes positions, en dur et sans nommer de colonne :
--
--        SELECT * FROM listeColonneTable
--         WHERE table_Name = upper('<NOM_TABLE>')
--         ORDER BY column_id ASC
--
--    puis utilise la 3e valeur comme nom de champ et la 4e comme type SQL
--    (decompiled/apj-core/bean/ListeColonneTable, ligne 289).
--
-- Consequence : les metadonnees des 6 tables du module apparaissent des la
-- creation des tables, sans aucune intervention. Toute insertion serait
-- d'ailleurs impossible, une vue etant ici non modifiable.
--
-- Cette section se limite donc a verifier que la vue expose bien les colonnes
-- attendues ; les requetes sont en section 6 bis.
-- La verification est detaillee en section 6 bis.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 6 bis. Verification des metadonnees APJ
--
-- Rappel du contrat lu dans le noyau APJ
-- (decompiled/apj-core/bean/ListeColonneTable, ligne 289) :
--
--   SELECT * FROM listeColonneTable
--    WHERE table_Name = upper('<NOM_TABLE>')
--    ORDER BY column_id ASC
--
-- puis utilisation des positions 3 (nom de champ) et 4 (type SQL), lues sans
-- nommer aucune colonne. LISTECOLONNETABLE etant une vue projetee sur
-- ALL_TAB_COLUMNS, ces positions sont COLUMN_NAME et DATA_TYPE.
--
-- 6 bis.1 Les 6 tables du module sont decrites par la vue.
--
-- Valeurs attendues : POULET 3, MAGASIN_ELEVAGE 5, COMPARTIMENT 4,
-- CONTROLE_POULET 12, REPARTITION 5, REPARTITION_FILLE 6.
--
--   SELECT table_Name, COUNT(*) AS nb_colonnes
--     FROM listeColonneTable
--    WHERE UPPER(table_Name) IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                                'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE')
--    GROUP BY table_Name
--    ORDER BY table_Name;
--
-- 6 bis.2 La vue voit bien le schema auquel on est connecte.
--
-- Si les OWNER renvoyes ne correspondent pas a votre schema, la vue n'expose
-- pas les tables du module et aucun formulaire APJ ne fonctionnera. A traiter
-- sur le socle applicatif.
--
--   SELECT USER AS schema_connecte FROM DUAL;
--
--   SELECT DISTINCT owner FROM listeColonneTable;
--
-- 6 bis.3 Les colonnes vues pour CONTROLE_POULET, a comparer aux 12 colonnes
-- du DDL. ETAT doit y figurer : ce champ est declare dans ClassEtat, hors de la
-- classe metier ControlePoulet, il ne peut donc pas etre deduit du code Java.
-- Son absence provoque une NullPointerException, les pages de saisie appelant
-- getChamp("etat") sans test de nullite : controle-poulet-saisie.jsp:34 et
-- repartition-saisie.jsp:24.
--
--   SELECT column_id, column_Name, data_Type, data_Length,
--          data_Precision, data_Scale
--     FROM listeColonneTable
--    WHERE UPPER(table_Name) = 'CONTROLE_POULET'
--    ORDER BY column_id;
--
-- 6 bis.4 Toutes les colonnes du DDL sont decrites par la vue. 0 ligne attendue.
--
--   SELECT c.table_name, c.column_name
--     FROM user_tab_columns c
--    WHERE c.table_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                           'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE')
--      AND NOT EXISTS (
--            SELECT 1 FROM listeColonneTable l
--             WHERE UPPER(l.owner) = USER
--               AND UPPER(l.table_Name) = c.table_name
--               AND UPPER(l.column_Name) = c.column_name);
--
-- 6 bis.5 La precision des colonnes Java de type int doit valoir 0.
--
-- bean.CGenUtil (ligne 2041) lit une precision non nulle en double, et la
-- conversion vers le champ int echoue. 0 ligne attendue.
--
--   SELECT table_Name, column_Name, data_Precision, data_Scale
--     FROM listeColonneTable
--    WHERE UPPER(column_Name) IN ('QUANTITETHEORIQUE','NBVIVANT','NBMORT',
--                                  'NBPERDU','CAPACITE','QTT','SANTE','ACTIF','ETAT')
--      AND NVL(data_Precision, 0) <> 0;
--
-- 6 bis.6 Verification directe que LISTECOLONNETABLE est bien une vue, et non
-- une table. C'est ce controle qui manquait a l'origine.
--
--   SELECT owner, object_name, object_type
--     FROM all_objects
--    WHERE object_name = 'LISTECOLONNETABLE';


-- ----------------------------------------------------------------------------
-- 7. Vues de disponibilite
--
-- Rappel des etats APJ (constante.ConstanteEtat) :
--   0 = annule, 1 = cree, 7 = interviewe, 9 = cloture, 11 = valide
-- Les vues ne retiennent que les objets VALIDES (etat >= 11).
-- ----------------------------------------------------------------------------

-- 7.1 Effectifs d'un lieu pour un poulet donne (reparti / restant a repartir)
CREATE OR REPLACE VIEW DISPONIBILITE_LIEU AS
SELECT
    cp.IDPOULET              AS idpoulet,
    cp.IDMAGASIN             AS idlieu,
    SUM(cp.NBVIVANT)         AS nbvivant,
    SUM(cp.NBPERDU)          AS nbperdu,
    SUM(cp.NBMORT)           AS nbmort,
    SUM(cp.QUANTITETHEORIQUE) AS quantitetheorique
FROM CONTROLE_POULET cp
WHERE cp.ETAT >= 11
GROUP BY cp.IDPOULET, cp.IDMAGASIN;

-- 7.2 Vivants effectivement distribues par compartiment
CREATE OR REPLACE VIEW DISPONIBILITE_COMPARTIMENT AS
SELECT
    rf.IDCOMPARTIMENT       AS idcompartiment,
    rf.SEXE                 AS sexe,
    SUM(rf.QTT)             AS effectif,
    COUNT(DISTINCT rf.IDREPARTITIONMERE) AS nbrepartition
FROM REPARTITION_FILLE rf
JOIN REPARTITION r ON r.ID = rf.IDREPARTITIONMERE
WHERE r.ETAT >= 11
GROUP BY rf.IDCOMPARTIMENT, rf.SEXE;

-- 7.3 Capacite restante par compartiment (capacite - occupation)
CREATE OR REPLACE VIEW CAPACITE_RESTANTE_COMPARTIMENT AS
SELECT
    c.ID           AS idcompartiment,
    c.NOM          AS nom,
    c.CAPACITE     AS capacite,
    c.IDPOULAILLER AS idpoulailler,
    NVL(NVL(dc.effectif, 0), 0) AS effectif,
    c.CAPACITE - NVL(dc.effectif, 0) AS capaciterestante
FROM COMPARTIMENT c
LEFT JOIN (
    SELECT IDCOMPARTIMENT, SUM(effectif) AS effectif
    FROM DISPONIBILITE_COMPARTIMENT
    GROUP BY IDCOMPARTIMENT
) dc ON dc.IDCOMPARTIMENT = c.ID;

-- 7.4 Vue de suivi de la chaine BC -> controle -> repartition
CREATE OR REPLACE VIEW SUIVI_ACHEMINEMENT AS
SELECT
    cp.ID                AS idcontrole,
    cp.DATY              AS datecontrole,
    me.TYPELIEU          AS typelieu,
    cp.TYPEANTECEDENT    AS typeantecedent,
    cp.IDANTECEDENT      AS idantecedent,
    cp.IDPOULET          AS idpoulet,
    cp.QUANTITETHEORIQUE AS quantitetheorique,
    cp.NBVIVANT          AS nbvivant,
    cp.NBMORT            AS nbmort,
    cp.NBPERDU           AS nbperdu,
    rp.ID                AS idrepartition,
    rp.DATY              AS daterepartition,
    rp.ETAT              AS etatrepartition,
    NVL(SUM(rf.QTT), 0)  AS qttrepartie
FROM CONTROLE_POULET cp
JOIN MAGASIN_ELEVAGE me ON me.ID = cp.IDMAGASIN
LEFT JOIN REPARTITION rp ON rp.IDCONTROLEPOULAILLER = cp.ID
LEFT JOIN REPARTITION_FILLE rf ON rf.IDREPARTITIONMERE = rp.ID
GROUP BY cp.ID, cp.DATY, me.TYPELIEU, cp.TYPEANTECEDENT, cp.IDANTECEDENT,
         cp.IDPOULET, cp.QUANTITETHEORIQUE, cp.NBVIVANT, cp.NBMORT, cp.NBPERDU,
         rp.ID, rp.DATY, rp.ETAT;

COMMIT;
-- ----------------------------------------------------------------------------
-- 8. Verification apres installation
--
-- 8.1 Les 6 tables, les 6 FONCTIONS et les 6 sequences sous-jacentes existent
--
-- Les objets nommes GETSEQ* doivent etre de type FUNCTION, pas SEQUENCE : le
-- noyau APJ les appelle par "select <nom> from dual".
--
--   SELECT object_name, object_type FROM user_objects
--    WHERE object_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                          'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE',
--                          'GETSEQPOULET','GETSEQMAGASINELEVAGE',
--                          'GETSEQCOMPARTIMENT','GETSEQCONTROLEPOULET',
--                          'GETSEQREPARTITION','GETSEQREPARTITIONFILLE',
--                          'SEQ_POULET','SEQ_MAGASIN_ELEVAGE',
--                          'SEQ_COMPARTIMENT','SEQ_CONTROLE_POULET',
--                          'SEQ_REPARTITION','SEQ_REPART_FILLE')
--    ORDER BY object_type, object_name;
--
-- 8.1 bis Chaque fonction de compteur repond
--
-- Les 6 requetes doivent chacune renvoyer un nombre. Une erreur ORA-00904 ou
-- ORA-06550 signale un objet cree dans le mauvais type.
--
--   SELECT GETSEQPOULET FROM dual;
--   SELECT GETSEQMAGASINELEVAGE FROM dual;
--   SELECT GETSEQCOMPARTIMENT FROM dual;
--   SELECT GETSEQCONTROLEPOULET FROM dual;
--   SELECT GETSEQREPARTITION FROM dual;
--   SELECT GETSEQREPARTITIONFILLE FROM dual;
--
-- 8.2 Les 4 vues existent
--
--   SELECT view_name FROM user_views
--    WHERE view_name IN ('DISPONIBILITE_LIEU','DISPONIBILITE_COMPARTIMENT',
--                        'CAPACITE_RESTANTE_COMPARTIMENT','SUIVI_ACHEMINEMENT');
--
-- 8.3 Les metadonnees couvrent bien les colonnes du DDL
--
-- La requete suivante doit renvoyer 0 ligne. Une ligne signale une colonne
-- creee en base mais invisible dans les formulaires APJ.
--
-- Adaptez les noms de colonnes de listeColonneTable a ceux affiches par la
-- section 6 (table_Name et column_Name dans l'exemple ci-dessous).
--
--   SELECT c.table_name, c.column_name
--     FROM user_tab_columns c
--    WHERE c.table_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                           'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE')
--      AND NOT EXISTS (
--            SELECT 1 FROM listeColonneTable l
--             WHERE UPPER(l.table_Name) = c.table_name
--               AND UPPER(l.column_Name) = c.column_name);
--
-- 8.4 Aucune contrainte portee par une colonne dupliquee
--
--   SELECT constraint_name, table_name, COUNT(*)
--     FROM user_cons_columns
--    WHERE table_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                         'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE')
--    GROUP BY constraint_name, table_name
--   HAVING COUNT(*) > 1;
--
-- 8.5 Aucune reference de cle etrangere non resolue, et etat des contraintes
--
--   SELECT constraint_name, search_condition_vc, status
--     FROM user_constraints
--    WHERE table_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                         'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE')
--      AND constraint_type IN ('P','R','C')
--      AND status <> 'ENABLED';
--
-- 8.6 La table SEXE contient bien les deux valeurs attendues par
--     RepartitionFille.controlerSexe (constantes 0 et 1)
--
--   SELECT id, val FROM sexe ORDER BY id;
--
-- ----------------------------------------------------------------------------
-- 9. Reinstallation
--
-- Le script est concu pour etre execute une fois sur un schema vide. En cas
-- d'echec en cours de route, ne le rejouez pas tel quel : les objets deja
-- crees provoqueraient ORA-00955 (nom deja utilise).
--
-- Executez d'abord le script de reinitialisation, qui supprime les vues,
-- tables, fonctions et sequences du module dans l'ordre des dependances :
--
--   @2026-10-05-acheminement-poules-pondeuses-reset.sql
--
-- Puis relancez le present script. La section 6 est idempotente : les lignes
-- listeColonneTable deja chargees ne sont pas dupliquees, il n'est donc pas
-- necessaire de les supprimer.
--
-- ----------------------------------------------------------------------------
-- 10. Depannage
--
-- 10.1 Avant toute premiere execution, ou pour etablir l'etat du socle APJ :
--
--   @2026-10-05-acheminement-poules-pondeuses-diagnostic.sql
--
-- 10.2 ORA-00955 : nom deja utilise par un objet existant
--
-- Le module est deja installe, ou l'execution precedente s'est interrompue.
-- Passez par le script de reinitialisation (section 9).
--
-- 10.3 ORA-00972 : identifiant trop long
--
-- Cause confirmee sur la base cible : Oracle Database 11g Enterprise Edition
-- Release 11.2.0.1.0, ou la limite est de 30 caracteres. Elle passe a 128 en
-- 12.2.
--
-- Les 42 identifiants du present script tiennent tous dans cette limite, le
-- plus long faisant 29 caracteres. Si ORA-00972 survient quand meme, il vient
-- d'un objet du socle de votre schema, pas de ce script : Oracle leve
-- l'erreur sans designer l'objet fautif. Cherchez la cause par dichotomie,
-- table par table.
--
-- 10.4 ORA-01745 : nom de variable de liaison invalide
--
-- Cause historique du script : les metadonnees etaient inserees via
-- EXECUTE IMMEDIATE ... USING, et la valeur nommee :or entrait en conflit
-- avec l'operateur SQL du meme nom.
--
-- Cette cause a disparu : aucune metadonnee n'est plus inseree (section 6),
-- et le script n'emploie plus aucune variable de liaison. L'erreur ne peut
-- donc plus provenir du present script.
--
-- 10.5 ORA-00942 : table ou vue inexistante
--
-- Presque toujours une consequence en cascade d'une erreur plus haute dans la
-- sortie. Une vue qui depend de CONTROLE_POULET echoue si CONTROLE_POULET n'a
-- pas ete cree. Traitez la premiere erreur, pas les suivantes.
--
-- 10.6 ORA-01031 : privileges insuffisants
--
-- Rencontre sur DISPONIBILITE_COMPARTIMENT alors que ses deux tables sources
-- (REPARTITION et REPARTITION_FILLE) existent. Deux pistes :
--
--   a) Cause reelle : le compte connecte n'est pas proprietaire des tables, ou
--      celles-ci ont ete creees par un autre compte. Verifiez :
--
--        SELECT owner, table_name FROM all_tables
--         WHERE table_name IN ('REPARTITION','REPARTITION_FILLE');
--
--      user_tables ne comporte pas de colonne OWNER : use all_tables, ou
--      comparez le proprietaire attendu avec
--
--        SELECT USER FROM dual;
--
--      Si la colonne OWNER est renseignee avec un autre compte que le votre,
--      tous les CREATE de ce script ont reussi avec un autre compte que
--      celui de la session : changez de compte.
--
--   b) Cause indirecte : une dependance de la vue est invalide, et Oracle
--      remonte ORA-01031 au lieu de ORA-00942. Verifiez l'etat de la vue
--      apres la creation :
--
--        SELECT object_name, object_type, status FROM user_objects
--         WHERE object_name = 'DISPONIBILITE_COMPARTIMENT';
--
--      STATUS a INVALID confirme ce cas : recreez la vue apres avoir corrige
--      la table qui bloque.
--
-- 10.7 ORA-00904 : identifiant non valide, sur un nom en GETSEQ...
--
-- C'est l'erreur qui survient quand l'objet compteur a ete cree en SEQUENCE
-- au lieu de FUNCTION. Le noyau APJ ne fait jamais :
--
--     select GETSEQPOULET.nextval from dual
--
-- mais, via ClassMAPTable.makePK puis Utilitaire.getMaxSeq :
--
--     select GETSEQPOULET from dual
--
-- Or une sequence n'est pas un objet appelable ainsi : Oracle repond
-- ORA-00904. Seul setNomSequenceDirecte produirait un vrai .nextval, et aucune
-- classe du projet ne s'en sert.
--
-- Correctif : creer une fonction sans parametre qui lit la sequence, comme
-- fait la section 1 de ce script.
--
--   CREATE SEQUENCE SEQ_POULET START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
--   CREATE OR REPLACE FUNCTION GETSEQPOULET RETURN NUMBER IS
--       v_next NUMBER;
--   BEGIN
--       SELECT SEQ_POULET.NEXTVAL INTO v_next FROM dual;
--       RETURN v_next;
--   END;
--   /
--
-- Verifiez ensuite le type reel des objets :
--
--   SELECT object_name, object_type FROM user_objects
--    WHERE object_name LIKE 'GETSEQ%';
--
-- Les 6 noms du module doivent apparaitre en FUNCTION. S'ils apparaissent en
-- SEQUENCE, c'est que la version precedente du script a ete installee :
-- executez le script de reinitialisation (section 9) puis celui-ci.
--
-- 10.8 Aucun formulaire APJ ne s'affiche, ou les colonnes du module
--      n'apparaissent pas dans les listes deroulantes
--
-- LISTECOLONNETABLE est une VUE du socle applicatif, projetee sur le
-- dictionnaire de donnees. Elle n'a rien a voir avec ce module : elle alimente
-- toutes les pages APJ. Aucune ligne n'a besoin d'etre inseree, les tables du
-- module y apparaissent des leur creation.
--
-- Le symptome ne vient donc pas de ce script, mais de l'une de ces causes :
--
--   a) La vue n'expose pas le schema courant. Elle porte un OWNER en colonne 1
--      qu'elle peut filtrer. Comparez-le au schema connecte :
--
--        SELECT USER FROM DUAL;
--        SELECT DISTINCT owner FROM listeColonneTable;
--
--      Si les valeurs divergent, le probleme est dans la definition de la vue,
--      cote socle applicatif.
--
--   b) Une colonne du module existe en base mais pas comme champ Java. Le
--      noyau ne conserve que l'intersection entre les colonnes vues et les
--      champs declares : une colonne sans champ Java est ignoree sans
--      diagnostic. Verifiez que chaque colonne du DDL a bien son champ :
--
--        SELECT c.table_name, c.column_name
--          FROM user_tab_columns c
--         WHERE c.table_name IN ('POULET','MAGASIN_ELEVAGE','COMPARTIMENT',
--                                'CONTROLE_POULET','REPARTITION','REPARTITION_FILLE')
--           AND NOT EXISTS (
--                 SELECT 1 FROM listeColonneTable l
--                  WHERE UPPER(l.owner) = USER
--                    AND UPPER(l.table_Name) = c.table_name
--                    AND UPPER(l.column_Name) = c.column_name);
--
--   c) Le cas ETAT. Ce champ est declare dans ClassEtat, hors des classes
--      metier ControlePoulet et Repartition : il n'apparait pas dans leurs
--      declarations. Yet les pages de saisie l'utilisent :
--
--        controle-poulet-saisie.jsp:34   getChamp("etat").getHtml(...)
--        repartition-saisie.jsp:24       getChamp("etat").getHtml(...)
--
--      Formulaire.getChamp renvoie null si le champ est absent, et l'appel
--      n'est pasprotege : la page echoue sur une NullPointerException. Ce n'est
--      un symptome propre a la base, il faut le corriger cote page.
