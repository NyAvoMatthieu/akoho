-- ============================================================================
-- Reinitialisation du module "acheminement des poules pondeuses"
-- Ref : 2026-10-05-acheminement-poules-pondeuses.sql
--
-- ATTENTION : ce script detruit les donnees des 6 tables du module.
-- N'executez-le que pour repartir d'un schema vide, typiquement apres une
-- installation incomplete ou pour rejouer des tests depuis le debut.
--
-- Usage : @2026-10-05-acheminement-poules-pondeuses-reset.sql
--
-- Les lignes listeColonneTable du module ne sont pas supprimees : la section 6
-- du script d'installation est idempotente, il suffit de la rejouer.
-- ============================================================================

SET SERVEROUTPUT ON

-- ----------------------------------------------------------------------------
-- 1. Suppression des vues (elles dependent des tables)
-- ----------------------------------------------------------------------------
DECLARE
    v_liste VARCHAR2(4000);
BEGIN
    SELECT LISTAGG(view_name, ', ') WITHIN GROUP (ORDER BY view_name)
      INTO v_liste
      FROM user_views
     WHERE view_name IN ('SUIVI_ACHEMINEMENT', 'CAPACITE_RESTANTE_COMPARTIMENT',
                          'DISPONIBILITE_COMPARTIMENT', 'DISPONIBILITE_LIEU');

    IF v_liste IS NOT NULL THEN
        FOR r IN (SELECT view_name FROM user_views
                   WHERE view_name IN ('SUIVI_ACHEMINEMENT',
                                        'CAPACITE_RESTANTE_COMPARTIMENT',
                                        'DISPONIBILITE_COMPARTIMENT',
                                        'DISPONIBILITE_LIEU')) LOOP
            EXECUTE IMMEDIATE 'DROP VIEW ' || r.view_name;
            DBMS_OUTPUT.PUT_LINE('vue supprimee      : ' || r.view_name);
        END LOOP;
    ELSE
        DBMS_OUTPUT.PUT_LINE('aucune vue a supprimer');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 2. Suppression des tables, dans l'ordre inverse des dependances
--
-- REPARTITION_FILLE -> REPARTITION -> CONTROLE_POULET -> COMPARTIMENT
--                   -> MAGASIN_ELEVAGE -> POULET
--
-- PURGE evite de peupler le corbeil de recyclage.
-- ----------------------------------------------------------------------------
DECLARE
    TYPE t_noms IS TABLE OF VARCHAR2(30);
    v_tables t_noms := t_noms('REPARTITION_FILLE', 'REPARTITION',
                              'CONTROLE_POULET', 'COMPARTIMENT',
                              'MAGASIN_ELEVAGE', 'POULET');
BEGIN
    FOR i IN 1 .. v_tables.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || v_tables(i) || ' PURGE';
            DBMS_OUTPUT.PUT_LINE('table supprimee    : ' || v_tables(i));
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -942 THEN
                DBMS_OUTPUT.PUT_LINE('table absente      : ' || v_tables(i));
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERREUR sur ' || v_tables(i)
                    || ' : ' || SQLERRM);
            END IF;
        END;
    END LOOP;
END;
/

-- ----------------------------------------------------------------------------
-- 3. Suppression des fonctions de compteur, puis des sequences
--
-- Les fonctions GETSEQ* sont supprimees en premier : une version anterieure de
-- ce script les avait peut-etre creees en SEQUENCE, et DROP SEQUENCE ne
-- supprimerait alors pas l'objet. La boucle tolere les deux types.
-- ----------------------------------------------------------------------------
DECLARE
    TYPE t_noms IS TABLE OF VARCHAR2(30);
    v_seq t_noms := t_noms('GETSEQREPARTITIONFILLE', 'GETSEQREPARTITION',
                            'GETSEQCONTROLEPOULET', 'GETSEQCOMPARTIMENT',
                            'GETSEQMAGASINELEVAGE', 'GETSEQPOULET');
BEGIN
    FOR i IN 1 .. v_seq.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP FUNCTION ' || v_seq(i);
            DBMS_OUTPUT.PUT_LINE('fonction supprimee: ' || v_seq(i));
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -2289 THEN
                BEGIN
                    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || v_seq(i);
                    DBMS_OUTPUT.PUT_LINE('sequence supprimee : ' || v_seq(i)
                        || '  (objet de type SEQUENCE)');
                EXCEPTION WHEN OTHERS THEN
                    IF SQLCODE = -2289 THEN
                        DBMS_OUTPUT.PUT_LINE('compteur absent   : ' || v_seq(i));
                    ELSE
                        DBMS_OUTPUT.PUT_LINE('ERREUR sur ' || v_seq(i)
                            || ' : ' || SQLERRM);
                    END IF;
                END;
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERREUR sur ' || v_seq(i)
                    || ' : ' || SQLERRM);
            END IF;
        END;
    END LOOP;
END;
/

DECLARE
    TYPE t_noms IS TABLE OF VARCHAR2(30);
    v_seq t_noms := t_noms('SEQ_REPART_FILLE', 'SEQ_REPARTITION',
                            'SEQ_CONTROLE_POULET', 'SEQ_COMPARTIMENT',
                            'SEQ_MAGASIN_ELEVAGE', 'SEQ_POULET');
BEGIN
    FOR i IN 1 .. v_seq.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || v_seq(i);
            DBMS_OUTPUT.PUT_LINE('sequence supprimee : ' || v_seq(i));
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE = -2289 THEN
                DBMS_OUTPUT.PUT_LINE('sequence absente   : ' || v_seq(i));
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERREUR sur ' || v_seq(i)
                    || ' : ' || SQLERRM);
            END IF;
        END;
    END LOOP;
END;
/

-- ----------------------------------------------------------------------------
-- 4. Verification : ne doit plus rester aucun objet du module
-- ----------------------------------------------------------------------------
SET PAGESIZE 200 LINESIZE 200 FEEDBACK OFF

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

-- Resultat attendu : aucun resultat.

-- Reexecuter ensuite le script d'installation :
-- @2026-10-05-acheminement-poules-pondeuses.sql