package ferme.acheminement;

import ferme.utils.ConstanteFerme;

/**
 * Regles de calcul pures de l'acheminement des poulets.
 * Ces methodes ne gorgent pas la base : elles sont testables isolement.
 */
public final class CalculAcheminement {

    private CalculAcheminement() {
    }

    /**
     * nbPerdu = quantiteTheorique - nbVivant - nbMort
     */
    public static int calculerNbPerdu(int quantiteTheorique, int nbVivant, int nbMort) throws Exception {
        controlerCoherenceControle(quantiteTheorique, nbVivant, nbMort);
        return quantiteTheorique - nbVivant - nbMort;
    }

    /**
     * Refuse nbVivant &lt; 0, nbMort &lt; 0 et nbVivant + nbMort &gt; quantiteTheorique.
     */
    public static void controlerCoherenceControle(int quantiteTheorique, int nbVivant, int nbMort) throws Exception {
        if (quantiteTheorique < 0) {
            throw new Exception("La quantité théorique ne peut pas être négative");
        }
        if (nbVivant < 0) {
            throw new Exception("Le nombre de vivants ne peut pas être négatif");
        }
        if (nbMort < 0) {
            throw new Exception("Le nombre de morts ne peut pas être négatif");
        }
        if (nbVivant + nbMort > quantiteTheorique) {
            throw new Exception("Le nombre de vivants (" + nbVivant + ") plus le nombre de morts (" + nbMort
                    + ") dépasse la quantité théorique (" + quantiteTheorique + ")");
        }
    }

    /**
     * La somme des quantités réparties doit égaler exactement les vivants du contrôle.
     */
    public static void controlerSommeRepartition(int somme, int nbVivantControle) throws Exception {
        if (somme != nbVivantControle) {
            throw new Exception("La somme des quantités réparties (" + somme
                    + ") doit être égale au nombre de vivants du contrôle de poulailler (" + nbVivantControle + ")");
        }
    }

    public static void controlerQuantiteLigne(int qtt) throws Exception {
        if (qtt <= 0) {
            throw new Exception("La quantité d'une ligne de répartition doit être strictement positive (reçu : " + qtt + ")");
        }
    }

    public static void controlerSante(int sante) throws Exception {
        if (sante < RepartitionFille.SANTE_MIN || sante > RepartitionFille.SANTE_MAX) {
            throw new Exception("La santé doit être comprise entre " + RepartitionFille.SANTE_MIN + " et "
                    + RepartitionFille.SANTE_MAX + " (reçu : " + sante + ")");
        }
    }

    public static void controlerSexe(String sexe) throws Exception {
        if (!ConstanteFerme.IDSEXEMALE.equals(sexe) && !ConstanteFerme.IDSEXEFEMELLE.equals(sexe)) {
            throw new Exception("Sexe non reconnu pour la ligne de répartition : " + sexe);
        }
    }

    public static void controlerCapacite(int occupationTotale, int capacite, String nomCompartiment) throws Exception {
        if (occupationTotale > capacite) {
            throw new Exception("La capacité du compartiment " + nomCompartiment + " (" + capacite
                    + ") est dépassée par l'occupation totale (" + occupationTotale + ")");
        }
    }
}