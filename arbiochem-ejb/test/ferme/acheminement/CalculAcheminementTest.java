package ferme.acheminement;

/**
 * Tests des regles metier pures de l'acheminement (sans base de donnees).
 * Les cas qui exigent la base (existence de l'antecedent, lieu, rollback)
 * sont verifies par le scenario JSP manuel du guide.
 */
public class CalculAcheminementTest {

    private static int reussis = 0;
    private static int echecs = 0;

    public static void main(String[] args) {
        testCas1Theorique100Avec90Vivant5Mort5Perdu();
        testCas2Refus90Vivant11Mort();
        testCas4RefusAntecedentInconnu();
        testCas5Repartition40Plus50Acceptee();
        testCas6Repartition40Plus49Refusee();
        testCas7QuantiteNulleOuNegativeRefusee();
        testCas8SanteHorsBornesRefusee();
        testCas10CapaciteDepasseeRefusee();
        testSanteBornesAcceptables();
        testSexeNonReconnuRefuse();

        System.out.println("");
        System.out.println("Reussis : " + reussis + " / Echecs : " + echecs);
        if (echecs > 0) {
            System.exit(1);
        }
    }

    /** Cas 1 : BC de 100, controle aéroport 90 vivants + 5 morts + 5 perdus accepté. */
    private static void testCas1Theorique100Avec90Vivant5Mort5Perdu() {
        try {
            int perdu = CalculAcheminement.calculerNbPerdu(100, 90, 5);
            verifier("cas 1 : 100 = 90 + 5 + 5", perdu == 5, "nbPerdu attendu 5, obtenu " + perdu);
        } catch (Exception e) {
            echec("cas 1 : 100 = 90 + 5 + 5", e);
        }
    }

    /** Cas 2 : 90 vivants + 11 morts sur 100 theoriques doit etre refuse. */
    private static void testCas2Refus90Vivant11Mort() {
        try {
            CalculAcheminement.calculerNbPerdu(100, 90, 11);
            echec("cas 2 : 90 + 11 > 100 refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 2 : 90 + 11 > 100 refuse");
        }
    }

    /** Cas 4 : type d'antécédent inconnu refuse. */
    private static void testCas4RefusAntecedentInconnu() {
        try {
            ControlePoulet controle = new ControlePoulet();
            controle.setTypeAntecedent("XYZ");
            controle.calculerQuantiteTheoriqueDepuisAntecedent(null);
            echec("cas 4 : antecedent inconnu refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 4 : antecedent inconnu refuse");
        }
    }

    /** Cas 5 : repartition 40 + 50 = 90 acceptee. */
    private static void testCas5Repartition40Plus50Acceptee() {
        try {
            CalculAcheminement.controlerSommeRepartition(40 + 50, 90);
            reussis("cas 5 : 40 + 50 = 90 accepte");
        } catch (Exception e) {
            echec("cas 5 : 40 + 50 = 90 accepte", e);
        }
    }

    /** Cas 6 : repartition 40 + 49 = 89 sur 90 vivants refusee. */
    private static void testCas6Repartition40Plus49Refusee() {
        try {
            CalculAcheminement.controlerSommeRepartition(40 + 49, 90);
            echec("cas 6 : 40 + 49 refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 6 : 40 + 49 refuse");
        }
    }

    /** Cas 7 : quantite nulle ou negative refusee. */
    private static void testCas7QuantiteNulleOuNegativeRefusee() {
        try {
            CalculAcheminement.controlerQuantiteLigne(0);
            echec("cas 7 : qtt = 0 refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 7 : qtt = 0 refuse");
        }
        try {
            CalculAcheminement.controlerQuantiteLigne(-5);
            echec("cas 7 : qtt = -5 refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 7 : qtt = -5 refuse");
        }
    }

    /** Cas 8 : sante -1 ou 11 refusee. */
    private static void testCas8SanteHorsBornesRefusee() {
        try {
            CalculAcheminement.controlerSante(-1);
            echec("cas 8 : sante -1 refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 8 : sante -1 refuse");
        }
        try {
            CalculAcheminement.controlerSante(11);
            echec("cas 8 : sante 11 refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 8 : sante 11 refuse");
        }
    }

    /** Cas 10 : capacite depassee refusee. */
    private static void testCas10CapaciteDepasseeRefusee() {
        try {
            CalculAcheminement.controlerCapacite(120, 100, "Compartiment A");
            echec("cas 10 : capacite depassee refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("cas 10 : capacite depassee refuse");
        }
    }

    private static void testSanteBornesAcceptables() {
        try {
            CalculAcheminement.controlerSante(0);
            CalculAcheminement.controlerSante(10);
            reussis("sante 0 et 10 acceptees");
        } catch (Exception e) {
            echec("sante 0 et 10 acceptees", e);
        }
    }

    private static void testSexeNonReconnuRefuse() {
        try {
            CalculAcheminement.controlerSexe("X");
            echec("sexe inconnu refuse", new Exception("aucune exception levee"));
        } catch (Exception e) {
            reussis("sexe inconnu refuse");
        }
        try {
            CalculAcheminement.controlerSexe("1");
            CalculAcheminement.controlerSexe("0");
            reussis("sexe 0 et 1 acceptes");
        } catch (Exception e) {
            echec("sexe 0 et 1 acceptes", e);
        }
    }

    private static void verifier(String nom, boolean condition, String message) {
        if (condition) {
            reussis(nom);
        } else {
            echec(nom, new Exception(message));
        }
    }

    private static void reussis(String nom) {
        reussis++;
        System.out.println("[OK]   " + nom);
    }

    private static void echec(String nom, Exception e) {
        echecs++;
        System.out.println("[FAIL] " + nom + " -> " + e.getMessage());
    }
}